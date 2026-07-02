#!/usr/bin/env bash

prepare_pod_workspace() {
  reset_directory "${POD_WORKSPACE}"

  cat >"${POD_WORKSPACE}/Podfile" <<PODFILE
platform :ios, '${MIN_IOS_VERSION}'
install! 'cocoapods', :integrate_targets => false

target 'MediaPipeSPMArtifacts' do
  pod 'MediaPipeTasksVision', '${MEDIAPIPE_VERSION}'
end
PODFILE
}

install_mediapipe_pods() {
  run_command env LANG=en_US.UTF-8 pod install --project-directory="${POD_WORKSPACE}"
}

stage_mediapipe_pod_artifacts() {
  mkdir -p "${ARTIFACTS_DIR}"

  copy_directory_contents \
    "${POD_WORKSPACE}/Pods/MediaPipeTasksVision/frameworks/MediaPipeTasksVision.xcframework" \
    "${ARTIFACTS_DIR}/MediaPipeTasksVision.xcframework"

  copy_directory_contents \
    "${POD_WORKSPACE}/Pods/MediaPipeTasksCommon/frameworks/MediaPipeTasksCommon.xcframework" \
    "${ARTIFACTS_DIR}/MediaPipeTasksCommon.xcframework"

  strip_intel_simulator_slice "${ARTIFACTS_DIR}/MediaPipeTasksVision.xcframework" "MediaPipeTasksVision"
  strip_intel_simulator_slice "${ARTIFACTS_DIR}/MediaPipeTasksCommon.xcframework" "MediaPipeTasksCommon"
}

mediapipe_graph_libraries_dir() {
  printf '%s\n' "${POD_WORKSPACE}/Pods/MediaPipeTasksCommon/frameworks/graph_libraries"
}
