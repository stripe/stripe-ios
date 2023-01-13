import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "CardImageVerification Example",
    options: .options(
        automaticSchemesOptions: .disabled,
        disableBundleAccessors: true,
        disableSynthesizedResourceAccessors: true
    ),
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
            settings: .stripeTargetSettings(
                baseXcconfigFilePath: "BuildConfigurations/CardImageVerification-Example"
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
                ),
            ],
            dependencies: [
                .target(name: "CardImageVerification Example"),
            ],
            settings: .stripeTargetSettings(
                baseXcconfigFilePath: "BuildConfigurations/CardImageVerification-ExampleUITests"
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
        ),
    ]
)
