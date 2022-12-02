import ProjectDescription

let project = Project(
    name: "CardImageVerification Example",
    options: .options(automaticSchemesOptions: .disabled),
    settings: .settings(
        configurations: [
            .debug(
                name: "Debug",
                xcconfig: "//BuildConfigurations/Project-Debug.xcconfig"
            ),
            .release(
                name: "Release",
                xcconfig: "//BuildConfigurations/Project-Release.xcconfig"
            ),
        ],
        defaultSettings: .none
    ),
    targets: [
        Target(
            name: "CardImageVerification Example",
            platform: .iOS,
            product: .app,
            productName: "CardImageVerificationExample",
            bundleId: "com.stripe.CardImageVerification-Example",
            infoPlist: "CardImageVerification Example/Info.plist",
            sources: "CardImageVerification Example/**/*.swift",
            resources: "CardImageVerification Example/Resources/**",
            dependencies: [
                .project(target: "StripeCore", path: "//StripeCore"),
                .project(target: "StripeCardScan", path: "//StripeCardScan"),
            ],
            settings: .settings(base: [
                "TARGETED_DEVICE_FAMILY": "1,2",
                "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
                "ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS": true,
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
            ])
        ),
        Target(
            name: "CardImageVerification ExampleUITests",
            platform: .iOS,
            product: .uiTests,
            productName: "CardImageVerificationExampleUITests",
            bundleId: "com.stripe.CardImageVerification-ExampleUITests",
            infoPlist: "CardImageVerification ExampleUITests/Info.plist",
            sources: "CardImageVerification ExampleUITests/*.swift",
            scripts: [
                .post(
                    script: """
                    if [ $PLATFORM_NAME == iphonesimulator ]; then
                        "CardImageVerification ExampleUITests/Scripts/CopyStripeCardScanTestResources.sh"
                    fi
                    """,
                    name: "Copy Test Resources from StripeCardScanTests",
                    inputPaths: [
                        "//StripeCardScan/StripeCardScanTests/Resources/synthetic_test_image.jpg",
                    ],
                    basedOnDependencyAnalysis: false
                )
            ],
            dependencies: [
                .target(name: "CardImageVerification Example"),
            ],
            settings: .settings(base: [
                "TARGETED_DEVICE_FAMILY": "1,2",
                "TEST_TARGET_NAME": "CardImageVerification Example",
            ])
        ),
    ],
    schemes: [
        Scheme(
            name: "CardImageVerification Example",
            buildAction: .buildAction(targets: [
                "CardImageVerification Example",
                "CardImageVerification ExampleUITests",
            ]),
            testAction: .targets(["CardImageVerification ExampleUITests"]),
            runAction: .runAction(executable: "CardImageVerification Example")
        )
    ]
)
