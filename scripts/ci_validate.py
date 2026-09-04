#!/usr/bin/env python3
"""Dependency-free repository checks for the Instacart pipeline."""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MAX_TRACKED_FILE_BYTES = 5 * 1024 * 1024
REPOSITORY_URL = "https://github.com/ItsYangCoder/instacart-pipeline.git"
BLOCKED_DATA_EXTENSIONS = {
    ".csv",
    ".csv.gz",
    ".parquet",
    ".avro",
    ".zip",
    ".tar",
    ".gz",
    ".db",
    ".sqlite",
    ".sqlite3",
}

SECRET_PATTERNS = (
    re.compile(r"dapi[0-9a-zA-Z]{20,}"),
    re.compile(r"gh[pousr]_[0-9A-Za-z_]{20,}"),
    re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
)

DESTRUCTIVE_SQL = re.compile(
    r"\b(?:DROP\s+(?:CATALOG|SCHEMA|TABLE)|TRUNCATE\s+TABLE)\b",
    re.IGNORECASE,
)


def tracked_paths() -> list[Path]:
    try:
        output = subprocess.check_output(
            ["git", "-C", str(ROOT), "ls-files", "-z"],
            text=False,
        )
    except (OSError, subprocess.CalledProcessError):
        return [path.relative_to(ROOT) for path in ROOT.rglob("*") if path.is_file()]

    return [Path(item) for item in output.decode().split("\0") if item]


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def validate() -> list[str]:
    errors: list[str] = []
    paths = tracked_paths()

    for relative_path in paths:
        path = ROOT / relative_path
        if not path.is_file():
            continue

        size = path.stat().st_size
        if size > MAX_TRACKED_FILE_BYTES:
            fail(
                errors,
                f"{relative_path}: file is larger than "
                f"{MAX_TRACKED_FILE_BYTES // (1024 * 1024)} MiB",
            )

        suffixes = "".join(path.suffixes).lower()
        if path.suffix.lower() in BLOCKED_DATA_EXTENSIONS or suffixes in BLOCKED_DATA_EXTENSIONS:
            fail(errors, f"{relative_path}: raw/binary data files are not allowed in Git")

        if path.suffix.lower() in {".sql", ".py", ".yml", ".yaml", ".json", ".md"}:
            text = path.read_text(encoding="utf-8")
            if any(pattern.search(text) for pattern in SECRET_PATTERNS):
                fail(errors, f"{relative_path}: possible credential detected")

    for notebook in ROOT.rglob("*.ipynb"):
        try:
            document = json.loads(notebook.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            fail(errors, f"{notebook.relative_to(ROOT)}: invalid notebook JSON ({exc})")
            continue

        if document.get("nbformat", 0) < 4 or not isinstance(document.get("cells"), list):
            fail(errors, f"{notebook.relative_to(ROOT)}: invalid notebook structure")

    for sql_file in ROOT.rglob("*.sql"):
        sql = sql_file.read_text(encoding="utf-8")
        executable_sql = re.sub(r"(?m)^\s*--.*$", "", sql)
        is_manual_check_placeholder = (
            sql_file.parent.name == "tests"
            and sql_file.name != "99_cicd_quality_gate.sql"
        )
        if (
            sql_file.name != "business_views.sql"
            and not is_manual_check_placeholder
            and not executable_sql.strip()
        ):
            fail(errors, f"{sql_file.relative_to(ROOT)}: SQL file has no executable statement")
        if DESTRUCTIVE_SQL.search(executable_sql):
            fail(errors, f"{sql_file.relative_to(ROOT)}: destructive SQL is blocked in CI")

    manifest_path = ROOT / "ops" / "instacart_job.json"
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(errors, f"ops/instacart_job.json: invalid JSON ({exc})")
        return errors

    git_source = manifest.get("git_source", {})
    if git_source.get("git_url") != REPOSITORY_URL:
        fail(errors, "ops/instacart_job.json: git source must point to this repository")
    if git_source.get("git_commit") != "__GIT_COMMIT__":
        fail(errors, "ops/instacart_job.json: Git commit must remain a runtime placeholder")
    if manifest.get("name") != "__DATABRICKS_JOB_NAME__":
        fail(errors, "ops/instacart_job.json: job name must remain a runtime placeholder")
    if manifest.get("tags", {}).get("environment") != "__DATABRICKS_ENVIRONMENT__":
        fail(errors, "ops/instacart_job.json: environment must remain a runtime placeholder")

    tasks = manifest.get("tasks")
    if not isinstance(tasks, list) or not tasks:
        fail(errors, "ops/instacart_job.json: tasks must be a non-empty list")
        return errors

    task_keys = [task.get("task_key") for task in tasks]
    if len(task_keys) != len(set(task_keys)):
        fail(errors, "ops/instacart_job.json: task keys must be unique")

    for task in tasks:
        task_key = task.get("task_key", "<missing task_key>")
        sql_task = task.get("sql_task")
        if not isinstance(sql_task, dict):
            fail(errors, f"{task_key}: only SQL tasks are allowed in the managed job")
            continue

        file_spec = sql_task.get("file", {})
        file_path = file_spec.get("path")
        if file_spec.get("source") != "GIT":
            fail(errors, f"{task_key}: SQL task must use source=GIT")
        if not isinstance(file_path, str) or not (ROOT / file_path).is_file():
            fail(errors, f"{task_key}: referenced SQL file does not exist: {file_path}")
        if sql_task.get("warehouse_id") != "__DATABRICKS_WAREHOUSE_ID__":
            fail(errors, f"{task_key}: warehouse ID must remain a runtime secret placeholder")

    init_sql = (ROOT / "src/sql/00_setup/00_init_schemas.sql").read_text(encoding="utf-8")
    if "CREATE SCHEMA IF NOT EXISTS instacart_gold" not in init_sql:
        fail(errors, "00_init_schemas.sql: Gold schema must be created")

    fact_sql = (ROOT / "src/sql/03_gold_model/fact_order_items.sql").read_text(encoding="utf-8")
    required_fact_fragments = (
        "timekey INT",
        "t.order_time_key AS timekey",
        "product_id, timekey, department_id",
        "source.timekey",
    )
    if any(fragment not in fact_sql for fragment in required_fact_fragments):
        fail(
            errors,
            "fact_order_items.sql: use fact timekey and dim_order_time.order_time_key consistently",
        )

    return errors


if __name__ == "__main__":
    validation_errors = validate()
    if validation_errors:
        print("CI validation failed:")
        for error in validation_errors:
            print(f"- {error}")
        sys.exit(1)

    print("CI validation passed: SQL, notebooks, manifest, secrets, and repository size are valid.")
