#!/bin/bash
set +x

curl -X "POST" "${SDK_FAILURE_NOTIFICATION_ENDPOINT}" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -d $'{
  "project": "RUN_MOBILESDK",
  "summary": "E2E test failed",
  "description": "Please ACK this ticket and investigate the failure. '"${CIRCLE_BUILD_URL}"'"
}'