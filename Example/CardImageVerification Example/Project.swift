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
            settings: .settings(
                configurations: [
                    .debug(
                        name: "Debug",
                        xcconfig: "BuildConfigurations/CardImageVerification-Example-Debug.xcconfig"
                    ),
                    .release(
                        name: "Release",
                        xcconfig: "BuildConfigurations/CardImageVerification-Example-Release.xcconfig"
                    ),
                ],
                defaultSettings: .none
            )
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
            settings: .settings(
                configurations: [
                    .debug(
                        name: "Debug",
                        xcconfig: "BuildConfigurations/CardImageVerification-ExampleUITests-Debug.xcconfig"
                    ),
                    .release(
                        name: "Release",
                        xcconfig: "BuildConfigurations/CardImageVerification-ExampleUITests-Release.xcconfig"
                    ),
                ],
                defaultSettings: .none
            )
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
