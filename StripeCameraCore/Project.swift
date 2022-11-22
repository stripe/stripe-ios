import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.stripeFramework(
    name: "StripeCameraCore",
    additionalTargets: [
        Target(
            name: "StripeCameraCoreTestUtils",
            platform: .iOS,
            product: .framework,
            bundleId: "com.stripe.StripeCameraCoreTestUtils",
            infoPlist: "StripeCameraCoreTestUtils/Info.plist",
            sources: "StripeCameraCoreTestUtils/**/*.swift",
            headers: .headers(
                public: "StripeCameraCoreTestUtils/StripeCameraCoreTestUtils.h"
            ),
            dependencies: [
                .xctest,
                .target(name: "StripeCameraCore"),
            ],
            settings: .settings(configurations: [
                .debug(
                    name: "Debug",
                    xcconfig: "//BuildConfigurations/StripeiOS Tests-Debug.xcconfig"
                ),
                .release(
                    name: "Release",
                    xcconfig: "//BuildConfigurations/StripeiOS Tests-Release.xcconfig"
                ),
            ])
        ),
    ],
    additionalSchemes: [
        Scheme(
            name: "StripeCameraCoreTestUtils",
            buildAction: .buildAction(targets: ["StripeCameraCoreTestUtils"])
        ),
    ],
    unitTestOptions: .testOptions(
        dependencies: [
            .target(name: "StripeCameraCoreTestUtils"),
        ]
    )
)

//let project = Project(
//    name: "StripeCameraCore",
//    settings: Settings.settings(
//        configurations: [
//            Configuration.debug(
//                name: "Debug",
//                xcconfig: "//BuildConfigurations/Project-Debug.xcconfig"
//            ),
//            Configuration.release(
//                name: "Release",
//                xcconfig: "//BuildConfigurations/Project-Release.xcconfig"
//            ),
//        ]
//    ),
//    targets: [
//        Target(
//            name: "StripeCameraCore",
//            platform: .iOS,
//            product: .framework,
//            bundleId: "com.stripe.stripe-camera-core",
//            infoPlist: "StripeCameraCore/Info.plist",
//            sources: "StripeCameraCore/Source/**/*.swift",
//            headers: Headers.headers(
//                public: "StripeCameraCore/StripeCameraCore.h"
//            ),
//            dependencies: [
//                .project(target: "StripeCore", path: "//StripeCore"),
//            ],
//            settings: Settings.settings(configurations: [
//                Configuration.debug(
//                    name: "Debug",
//                    xcconfig: "//BuildConfigurations/StripeiOS-Debug.xcconfig"
//                ),
//                Configuration.release(
//                    name: "Release",
//                    xcconfig: "//BuildConfigurations/StripeiOS-Release.xcconfig"
//                ),
//            ])
//        ),
//        Target(
//            name: "StripeCameraCoreTestUtils",
//            platform: .iOS,
//            product: .framework,
//            bundleId: "com.stripe.StripeCameraCoreTestUtils",
//            infoPlist: "StripeCameraCoreTestUtils/Info.plist",
//            sources: "StripeCameraCoreTestUtils/**/*.swift",
//            headers: Headers.headers(
//                public: "StripeCameraCoreTestUtils/StripeCameraCoreTestUtils.h"
//            ),
//            dependencies: [
//                .xctest,
//                .target(name: "StripeCameraCore"),
//            ],
//            settings: Settings.settings(configurations: [
//                Configuration.debug(
//                    name: "Debug",
//                    xcconfig: "//BuildConfigurations/StripeiOS Tests-Debug.xcconfig"
//                ),
//                Configuration.release(
//                    name: "Release",
//                    xcconfig: "//BuildConfigurations/StripeiOS Tests-Release.xcconfig"
//                ),
//            ])
//        ),
//        Target(
//            name: "StripeCameraCoreTests",
//            platform: .iOS,
//            product: .unitTests,
//            bundleId: "com.stripe.StripeCameraCoreTests",
//            infoPlist: "StripeCameraCoreTests/Info.plist",
//            sources: "StripeCameraCoreTests/**/*.swift",
//            dependencies: [
//                .xctest,
//                .target(name: "StripeCameraCore"),
//                .target(name: "StripeCameraCoreTestUtils"),
//            ],
//            settings: Settings.settings(configurations: [
//                Configuration.debug(
//                    name: "Debug",
//                    xcconfig: "//BuildConfigurations/StripeiOS Tests-Debug.xcconfig"
//                ),
//                Configuration.release(
//                    name: "Release",
//                    xcconfig: "//BuildConfigurations/StripeiOS Tests-Release.xcconfig"
//                ),
//            ])
//        ),
//    ],
//    resourceSynthesizers: []
//)
