// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MediaPipeSPM",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "MediaPipeSPM",
            targets: ["MediaPipeSPMRuntime"]
        ),
    ],
    targets: [
        .target(
            name: "MediaPipeSPMRuntime",
            dependencies: ["MediaPipeSPMLinkSupport"]
        ),
        .target(
            name: "MediaPipeSPMLinkSupport",
            dependencies: [
                "MediaPipeCommonGraphLibraries",
                "MediaPipeTasksCommon",
                "MediaPipeTasksVision",
            ],
            linkerSettings: [
                .unsafeFlags(["-ObjC"]),
                .linkedFramework("CoreMedia"),
                .linkedFramework("CoreVideo"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("Accelerate"),
                .linkedLibrary("c++"),
                .linkedLibrary("z"),
            ]
        ),
        .binaryTarget(
            name: "MediaPipeTasksVision",
            path: "Artifacts/MediaPipeTasksVision.xcframework"
        ),
        .binaryTarget(
            name: "MediaPipeCommonGraphLibraries",
            path: "Artifacts/MediaPipeCommonGraphLibraries.xcframework"
        ),
        .binaryTarget(
            name: "MediaPipeTasksCommon",
            path: "Artifacts/MediaPipeTasksCommon.xcframework"
        ),
    ]
)
