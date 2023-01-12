import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "Stripe3DS2",
    options: .options(
        automaticSchemesOptions: .disabled,
        disableBundleAccessors: true,
        disableSynthesizedResourceAccessors: true
    ),
    packages: [
        .remote(
            url: "https://github.com/uber/ios-snapshot-test-case",
            requirement: .upToNextMajor(from: "8.0.0")
        ),
    ],
    settings: .settings(
        configurations: [
            .debug(
                name: "Debug",
                xcconfig: "BuildConfigurations/Project-Debug.xcconfig"
            ),
            .release(
                name: "Release",
                xcconfig: "BuildConfigurations/Project-Release.xcconfig"
            ),
        ],
        defaultSettings: .none
    ),
    targets: [
        Target(
            name: "Stripe3DS2",
            platform: .iOS,
            product: .framework,
            bundleId: "com.stripe.stripe-3ds2",
            infoPlist: "Stripe3DS2/Info.plist",
            sources: "Stripe3DS2/**/*.m",
            resources: "Stripe3DS2/Resources/**",
            headers: .headers(
                public: [
                    "Stripe3DS2/include/*.h",
                ],
                project: "Stripe3DS2/*.h"
            ),
            settings: .stripeTargetSettings(
                baseXcconfigFilePath: "BuildConfigurations/Stripe3DS2"
            )
        ),
        Target(
            name: "Stripe3DS2Tests",
            platform: .iOS,
            product: .unitTests,
            bundleId: "com.stripe.Stripe3DS2Tests",
            infoPlist: "Stripe3DS2Tests/Info.plist",
            sources: "Stripe3DS2Tests/**/*.m",
            resources: "Stripe3DS2Tests/JSON/**",
            headers: .headers(
                project: "Stripe3DS2/**/*.h"
            ),
            dependencies: [
                .xctest,
                .target(name: "Stripe3DS2"),
            ],
            settings: .stripeTargetSettings(
                baseXcconfigFilePath: "BuildConfigurations/Stripe3DS2Tests"
            )
        ),
        Target(
            name: "Stripe3DS2DemoUI",
            platform: .iOS,
            product: .app,
            bundleId: "com.stripe.Stripe3DS2DemoUI",
            infoPlist: "Stripe3DS2DemoUI/Info.plist",
            sources: "Stripe3DS2DemoUI/Sources/**/*.m",
            resources: "Stripe3DS2DemoUI/Resources/**",
            headers: .headers(
                project: "Stripe3DS2DemoUI/Sources/**/*.h"
            ),
            dependencies: [
                .target(name: "Stripe3DS2"),
            ],
            settings: .stripeTargetSettings(
                baseXcconfigFilePath: "BuildConfigurations/Stripe3DS2DemoUI"
            )
        ),
        Target(
            name: "Stripe3DS2DemoUITests",
            platform: .iOS,
            product: .unitTests,
            bundleId: "com.stripe.Stripe3DS2DemoUITests",
            infoPlist: "Stripe3DS2DemoUITests/Info.plist",
            sources: "Stripe3DS2DemoUITests/**/*.m",
            dependencies: [
                .xctest,
                .target(name: "Stripe3DS2"),
                .target(name: "Stripe3DS2DemoUI"),
                .package(product: "iOSSnapshotTestCase"),
            ],
            settings: .stripeTargetSettings(
                baseXcconfigFilePath: "BuildConfigurations/Stripe3DS2DemoUITests"
            )
        ),
    ],
    schemes: [
        Scheme(
            name: "Stripe3DS2",
            buildAction: .buildAction(targets: ["Stripe3DS2"]),
            testAction: .targets(["Stripe3DS2Tests"])
        ),
        Scheme(
            name: "Stripe3DS2DemoUI",
            buildAction: .buildAction(targets: ["Stripe3DS2DemoUI"]),
            testAction: .targets(
                ["Stripe3DS2DemoUITests"],
                arguments: Arguments(
                    environment: [
                        "FB_REFERENCE_IMAGE_DIR":
                            "$(SOURCE_ROOT)/../Tests/ReferenceImages",
                    ]
                ),
                expandVariableFromTarget: "Stripe3DS2DemoUITests"
            ),
            runAction: .runAction(executable: "Stripe3DS2DemoUI")
        ),
    ]
)
