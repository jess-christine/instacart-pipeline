#!/usr/bin/env bash
set -euo pipefail

: "${DATABRICKS_HOST:?DATABRICKS_HOST is required}"
: "${DATABRICKS_TOKEN:?DATABRICKS_TOKEN is required}"
: "${DATABRICKS_WAREHOUSE_ID:?DATABRICKS_WAREHOUSE_ID is required}"
: "${GITHUB_SHA:?GITHUB_SHA is required}"
: "${DATABRICKS_ENVIRONMENT:?DATABRICKS_ENVIRONMENT is required}"
: "${DATABRICKS_JOB_NAME:?DATABRICKS_JOB_NAME is required}"

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
job_name="${DATABRICKS_JOB_NAME}"
host="${DATABRICKS_HOST%/}"
api_base="${host}/api/2.2"
payload_file="$(mktemp)"
trap 'rm -f "$payload_file"' EXIT

curl_json() {
  curl --fail-with-body --silent --show-error --retry 2 --retry-delay 2 \
    --retry-all-errors \
    -H "Authorization: Bearer ${DATABRICKS_TOKEN}" \
    -H "Content-Type: application/json" \
    "$@"
}

jq \
  --arg commit "$GITHUB_SHA" \
  --arg warehouse "$DATABRICKS_WAREHOUSE_ID" \
  --arg environment "$DATABRICKS_ENVIRONMENT" \
  --arg job_name "$DATABRICKS_JOB_NAME" \
  '.name = $job_name
   | .git_source.git_commit = $commit
   | .tags.environment = $environment
   | .tasks |= map(.sql_task.warehouse_id = $warehouse)' \
  "${repository_root}/ops/instacart_job.json" > "$payload_file"

jobs_response="$(curl_json -G "${api_base}/jobs/list" \
  --data-urlencode "name=${job_name}" \
  --data-urlencode "limit=100")"

job_id="$(jq -r --arg name "$job_name" \
  '.jobs[]? | select(.settings.name == $name) | .job_id' \
  <<<"$jobs_response" | head -n 1)"

if [[ -z "$job_id" ]]; then
  create_response="$(curl_json -X POST "${api_base}/jobs/create" \
    --data-binary "@${payload_file}")"
  job_id="$(jq -er '.job_id' <<<"$create_response")"
  echo "Created Databricks job ${job_id}."
else
  reset_payload="$(jq --argjson job_id "$job_id" \
    '{job_id: $job_id, new_settings: .}' "$payload_file")"
  curl_json -X POST "${api_base}/jobs/reset" --data "$reset_payload" >/dev/null
  echo "Updated Databricks job ${job_id}."
fi

run_response="$(curl_json -X POST "${api_base}/jobs/run-now" \
  --data "$(jq -n --argjson job_id "$job_id" '{job_id: $job_id}')")"
run_id="$(jq -er '.run_id' <<<"$run_response")"
run_url="$(jq -r '.run_page_url // empty' <<<"$run_response")"

if [[ -n "$run_url" ]]; then
  echo "Databricks run: ${run_url}"
fi

print_failure_details() {
  local failed_tasks task_key task_run_id task_state task_result state_message task_url
  local parent_url
  parent_url="$(jq -r '.run_page_url // empty' <<<"$run_response")"

  echo "Databricks run \${run_id} failed." >&2
  if [[ -n "$parent_url" ]]; then
    echo "Databricks URL: \${parent_url}" >&2
  fi

  failed_tasks="$(jq -r '
    .tasks[]?
    | select(
        (.state.result_state // "") == "FAILED"
        or (.state.life_cycle_state // "") == "INTERNAL_ERROR"
      )
    | [
        (.task_key // "unknown"),
        (.run_id // ""),
        (.state.life_cycle_state // "unknown"),
        (.state.result_state // "unknown"),
        (.state.state_message // "No state message"),
        (.run_page_url // "")
      ]
    | @tsv
  ' <<<"$run_response")"

  if [[ -z "$failed_tasks" ]]; then
    jq -r '.state.state_message // "No Databricks state message."' <<<"$run_response" >&2
    return
  fi

  while IFS=
while (( SECONDS < deadline )); do
  run_response="$(curl_json -G "${api_base}/jobs/runs/get" \
    --data-urlencode "run_id=${run_id}")"
  lifecycle_state="$(jq -r '.state.life_cycle_state // empty' <<<"$run_response")"
  result_state="$(jq -r '.state.result_state // empty' <<<"$run_response")"

  case "$lifecycle_state" in
    TERMINATED|SKIPPED|INTERNAL_ERROR)
      if [[ "$result_state" == "SUCCESS" ]]; then
        echo "Databricks job run ${run_id} succeeded."
        exit 0
      fi
      print_failure_details
      echo "Databricks job run ${run_id} ended with ${result_state:-${lifecycle_state}}." >&2
      exit 1
      ;;
  esac

  sleep 20
done

echo "Databricks job run ${run_id} exceeded the 120-minute CI timeout; canceling it." >&2
curl_json -X POST "${api_base}/jobs/runs/cancel" \
  --data "$(jq -n --argjson run_id "$run_id" '{run_id: $run_id}')" >/dev/null || true
exit 1
\t' read -r task_key task_run_id task_state task_result state_message task_url; do
    echo "Failed task: \${task_key}" >&2
    echo "  State: \${task_state}/\${task_result}" >&2
    echo "  Message: \${state_message}" >&2
    if [[ -n "$task_url" ]]; then
      echo "  Databricks task URL: \${task_url}" >&2
    fi

    if [[ -n "$task_run_id" ]]; then
      task_output=""
      if task_output="$(curl_json -G "\${api_base}/jobs/runs/get-output" \
        --data-urlencode "run_id=\${task_run_id}" 2>/dev/null)"; then
        jq -r '
          .error // .error_message // .notebook_output.result // empty
        ' <<<"$task_output" | sed 's/^/  Output: /' >&2
      fi
    fi
  done <<<"$failed_tasks"
}

deadline=$((SECONDS + 7200))
while (( SECONDS < deadline )); do
  run_response="$(curl_json -G "${api_base}/jobs/runs/get" \
    --data-urlencode "run_id=${run_id}")"
  lifecycle_state="$(jq -r '.state.life_cycle_state // empty' <<<"$run_response")"
  result_state="$(jq -r '.state.result_state // empty' <<<"$run_response")"

  case "$lifecycle_state" in
    TERMINATED|SKIPPED|INTERNAL_ERROR)
      if [[ "$result_state" == "SUCCESS" ]]; then
        echo "Databricks job run ${run_id} succeeded."
        exit 0
      fi
      echo "Databricks job run ${run_id} ended with ${result_state:-${lifecycle_state}}." >&2
      exit 1
      ;;
  esac

  sleep 20
done

echo "Databricks job run ${run_id} exceeded the 120-minute CI timeout; canceling it." >&2
curl_json -X POST "${api_base}/jobs/runs/cancel" \
  --data "$(jq -n --argjson run_id "$run_id" '{run_id: $run_id}')" >/dev/null || true
exit 1
