#!/usr/bin/env bash

MEDIAPIPE_VERSION="${MEDIAPIPE_VERSION:-0.10.21}"
MIN_IOS_VERSION="${MIN_IOS_VERSION:-13.0}"
GRAPH_ARTIFACT_NAME="MediaPipeCommonGraphLibraries"

configure_refresh_paths() {
  local script_dir="$1"

  PACKAGE_ROOT="$(cd "${script_dir}/.." && pwd)"
  ARTIFACTS_DIR="${PACKAGE_ROOT}/Artifacts"
  BUILD_ROOT="${PACKAGE_ROOT}/.build/artifact-refresh"
  POD_WORKSPACE="${BUILD_ROOT}/Pods"
  GRAPH_BUILD_ROOT="${BUILD_ROOT}/${GRAPH_ARTIFACT_NAME}"

  export PACKAGE_ROOT ARTIFACTS_DIR BUILD_ROOT POD_WORKSPACE GRAPH_BUILD_ROOT
}
