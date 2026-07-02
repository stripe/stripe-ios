#!/usr/bin/env bash

assemble_graph_artifact() {
  local graph_libraries_dir
  graph_libraries_dir="$(mediapipe_graph_libraries_dir)"

  local device_graph_library="${graph_libraries_dir}/libMediaPipeTasksCommon_device_graph.a"
  local simulator_graph_library="${graph_libraries_dir}/libMediaPipeTasksCommon_simulator_graph.a"

  require_file "${device_graph_library}"
  require_file "${simulator_graph_library}"

  reset_directory "${GRAPH_BUILD_ROOT}"

  local device_framework="${GRAPH_BUILD_ROOT}/iphoneos/${GRAPH_ARTIFACT_NAME}.framework"
  local simulator_framework="${GRAPH_BUILD_ROOT}/iphonesimulator/${GRAPH_ARTIFACT_NAME}.framework"

  write_framework_bundle "${device_framework}" "iPhoneOS"
  write_framework_bundle "${simulator_framework}" "iPhoneSimulator"

  copy_graph_library_into_framework "${device_graph_library}" "${device_framework}"
  copy_graph_library_into_framework "${simulator_graph_library}" "${simulator_framework}"
  create_static_graph_xcframework "${device_framework}" "${simulator_framework}"
}

copy_graph_library_into_framework() {
  local graph_library="$1"
  local framework_dir="$2"

  run_command ditto "${graph_library}" "${framework_dir}/${GRAPH_ARTIFACT_NAME}"
}

create_static_graph_xcframework() {
  local device_framework="$1"
  local simulator_framework="$2"
  local output_path="${ARTIFACTS_DIR}/${GRAPH_ARTIFACT_NAME}.xcframework"

  rm -rf "${output_path}"

  run_command xcodebuild \
    -create-xcframework \
    -framework "${device_framework}" \
    -framework "${simulator_framework}" \
    -output "${output_path}"

  strip_intel_simulator_slice "${output_path}" "${GRAPH_ARTIFACT_NAME}"
}

write_framework_bundle() {
  local framework_dir="$1"
  local supported_platform="$2"

  mkdir -p "${framework_dir}/Headers" "${framework_dir}/Modules"

  printf '#import <Foundation/Foundation.h>\n' >"${framework_dir}/Headers/${GRAPH_ARTIFACT_NAME}.h"

  cat >"${framework_dir}/Modules/module.modulemap" <<MODULEMAP
framework module ${GRAPH_ARTIFACT_NAME} {
  umbrella header "${GRAPH_ARTIFACT_NAME}.h"
  export *
  module * { export * }
}
MODULEMAP

  cat >"${framework_dir}/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>${GRAPH_ARTIFACT_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>com.stripe.${GRAPH_ARTIFACT_NAME}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${GRAPH_ARTIFACT_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>FMWK</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleSupportedPlatforms</key>
  <array>
    <string>${supported_platform}</string>
  </array>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>MinimumOSVersion</key>
  <string>${MIN_IOS_VERSION}</string>
</dict>
</plist>
PLIST
}
