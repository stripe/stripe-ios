#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/refresh/config.sh"
source "${SCRIPT_DIR}/refresh/commands.sh"
source "${SCRIPT_DIR}/refresh/pod_artifacts.sh"
source "${SCRIPT_DIR}/refresh/graph_artifact.sh"

main() {
  configure_refresh_paths "${SCRIPT_DIR}"
  require_refresh_tools
  prepare_pod_workspace
  install_mediapipe_pods
  stage_mediapipe_pod_artifacts
  assemble_graph_artifact

  echo "Refreshed MediaPipeSPM artifacts in ${ARTIFACTS_DIR}"
}

main "$@"
