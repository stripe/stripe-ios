#!/usr/bin/env bash

assemble_graph_artifact() {
  local graph_libraries_dir
  graph_libraries_dir="$(mediapipe_graph_libraries_dir)"

  local device_graph_library="${graph_libraries_dir}/libMediaPipeTasksCommon_device_graph.a"
  local simulator_graph_library="${graph_libraries_dir}/libMediaPipeTasksCommon_simulator_graph.a"

  require_file "${device_graph_library}"
  require_file "${simulator_graph_library}"

  reset_directory "${GRAPH_BUILD_ROOT}"
  printf 'void MediaPipeSPMKeepAlive(void) {}\n' >"${BUILD_ROOT}/keepalive.c"

  local device_framework="${GRAPH_BUILD_ROOT}/iphoneos/${GRAPH_ARTIFACT_NAME}.framework"
  local simulator_framework="${GRAPH_BUILD_ROOT}/iphonesimulator/${GRAPH_ARTIFACT_NAME}.framework"

  write_framework_bundle "${device_framework}" "iPhoneOS"
  write_framework_bundle "${simulator_framework}" "iPhoneSimulator"

  build_device_graph_binary "${device_framework}" "${device_graph_library}"
  build_simulator_graph_binary "${simulator_framework}" "${simulator_graph_library}"
  create_graph_xcframework "${device_framework}" "${simulator_framework}"
}

build_device_graph_binary() {
  local framework_dir="$1"
  local graph_library="$2"
  local object_path="${GRAPH_BUILD_ROOT}/keepalive-device-arm64.o"

  compile_keepalive_object \
    iphoneos \
    "arm64-apple-ios${MIN_IOS_VERSION}" \
    "${object_path}"

  link_graph_binary \
    iphoneos \
    "arm64-apple-ios${MIN_IOS_VERSION}" \
    "${object_path}" \
    "${graph_library}" \
    "${ARTIFACTS_DIR}/MediaPipeTasksCommon.xcframework/ios-arm64" \
    "${framework_dir}/${GRAPH_ARTIFACT_NAME}"
}

build_simulator_graph_binary() {
  local framework_dir="$1"
  local graph_library="$2"
  local arm64_binary="${GRAPH_BUILD_ROOT}/${GRAPH_ARTIFACT_NAME}-simulator-arm64"
  local x86_binary="${GRAPH_BUILD_ROOT}/${GRAPH_ARTIFACT_NAME}-simulator-x86_64"

  build_simulator_graph_slice arm64 "${graph_library}" "${arm64_binary}"
  build_simulator_graph_slice x86_64 "${graph_library}" "${x86_binary}"

  run_command lipo \
    -create \
    "${arm64_binary}" \
    "${x86_binary}" \
    -output "${framework_dir}/${GRAPH_ARTIFACT_NAME}"
}

build_simulator_graph_slice() {
  local architecture="$1"
  local graph_library="$2"
  local output_binary="$3"
  local target="${architecture}-apple-ios${MIN_IOS_VERSION}-simulator"
  local object_path="${GRAPH_BUILD_ROOT}/keepalive-simulator-${architecture}.o"

  compile_keepalive_object iphonesimulator "${target}" "${object_path}"

  link_graph_binary \
    iphonesimulator \
    "${target}" \
    "${object_path}" \
    "${graph_library}" \
    "${ARTIFACTS_DIR}/MediaPipeTasksCommon.xcframework/ios-arm64_x86_64-simulator" \
    "${output_binary}"
}

compile_keepalive_object() {
  local sdk="$1"
  local target="$2"
  local object_path="$3"

  run_command xcrun \
    --sdk "${sdk}" \
    clang \
    -target "${target}" \
    -isysroot "$(sdk_path "${sdk}")" \
    -fembed-bitcode-marker \
    -c "${BUILD_ROOT}/keepalive.c" \
    -o "${object_path}"
}

link_graph_binary() {
  local sdk="$1"
  local target="$2"
  local object_path="$3"
  local graph_library="$4"
  local mediapipe_common_framework_parent="$5"
  local output_binary="$6"

  run_command xcrun \
    --sdk "${sdk}" \
    clang \
    -target "${target}" \
    -dynamiclib \
    -isysroot "$(sdk_path "${sdk}")" \
    -install_name "@rpath/${GRAPH_ARTIFACT_NAME}.framework/${GRAPH_ARTIFACT_NAME}" \
    -compatibility_version 1 \
    -current_version 1 \
    -ObjC \
    -lc++ \
    -F "${mediapipe_common_framework_parent}" \
    "${object_path}" \
    -force_load "${graph_library}" \
    -framework MediaPipeTasksCommon \
    -framework AVFoundation \
    -framework Accelerate \
    -framework AssetsLibrary \
    -framework CoreFoundation \
    -framework CoreGraphics \
    -framework CoreImage \
    -framework CoreMedia \
    -framework CoreVideo \
    -framework Foundation \
    -framework ImageIO \
    -framework Metal \
    -framework OpenGLES \
    -framework QuartzCore \
    -framework UIKit \
    -o "${output_binary}"
}

create_graph_xcframework() {
  local device_framework="$1"
  local simulator_framework="$2"
  local output_path="${ARTIFACTS_DIR}/${GRAPH_ARTIFACT_NAME}.xcframework"

  rm -rf "${output_path}"

  run_command xcodebuild \
    -create-xcframework \
    -framework "${device_framework}" \
    -framework "${simulator_framework}" \
    -output "${output_path}"
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

sdk_path() {
  local sdk="$1"
  capture_command xcrun --sdk "${sdk}" --show-sdk-path
}

require_file() {
  if [[ ! -f "$1" ]]; then
    echo "error: missing expected file: $1" >&2
    exit 1
  fi
}
