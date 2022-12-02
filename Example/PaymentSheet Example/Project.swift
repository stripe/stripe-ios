import ProjectDescription

let project = Project(
    name: "PaymentSheet Example",
    options: .options(automaticSchemesOptions: .disabled),
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
            name: "PaymentSheet Example",
            platform: .iOS,
            product: .app,
            productName: "PaymentSheetExample",
            bundleId: "com.stripe.PaymentSheet-Example",
            infoPlist: "PaymentSheet Example/Info.plist",
            sources: "PaymentSheet Example/*.swift",
            resources: "PaymentSheet Example/Resources/**",
            dependencies: [
                .project(target: "StripeCore", path: "//StripeCore"),
                .project(target: "StripeUICore", path: "//StripeUICore"),
                .project(target: "StripeApplePay", path: "//StripeApplePay"),
                .project(target: "Stripe3DS2", path: "//Stripe3DS2"),
                .project(target: "StripePayments", path: "//StripePayments"),
                .project(target: "StripePaymentsUI", path: "//StripePaymentsUI"),
                .project(target: "StripePaymentSheet", path: "//StripePaymentSheet"),
                .project(
                    target: "StripeFinancialConnections",
                    path: "//StripeFinancialConnections"
                ),
            ],
            settings: .settings(base: [
                "TARGETED_DEVICE_FAMILY": "1,2",
                "SUPPORTS_MACCATALYST": true,
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
            ])
        ),
        Target(
            name: "PaymentSheetUITest",
            platform: .iOS,
            product: .uiTests,
            productName: "PaymentSheetUITest",
            bundleId: "com.stripe.PaymentSheetUITest",
            infoPlist: "PaymentSheetUITest/Info.plist",
            sources: "PaymentSheetUITest/*.swift",
            resources: [
                .folderReference(path: "PaymentSheetUITest/MockFiles"),
            ],
            dependencies: [
                .target(name: "PaymentSheet Example"),
                .project(target: "StripeCoreTestUtils", path: "//StripeCore"),
                .package(product: "iOSSnapshotTestCase"),
            ],
            settings: .settings(base: [
                "TARGETED_DEVICE_FAMILY": "1,2",
            ])
        ),
        Target(
            name: "PaymentSheetLocalizationScreenshotGenerator",
            platform: .iOS,
            product: .uiTests,
            productName: "PaymentSheetLocalizationScreenshotGenerator",
            bundleId: "com.stripe.PaymentSheetLocalizationScreenshotGenerator",
            infoPlist: "PaymentSheetLocalizationScreenshotGenerator/Info.plist",
            sources: "PaymentSheetLocalizationScreenshotGenerator/*.swift",
            dependencies: [
                .target(name: "PaymentSheet Example"),
            ],
            settings: .settings(base: [
                "TARGETED_DEVICE_FAMILY": "1,2",
                "IPHONEOS_DEPLOYMENT_TARGET": "14.5",
            ])
        ),
    ],
    schemes: [
        Scheme(
            name: "PaymentSheet Example",
            buildAction: .buildAction(targets: [
                "PaymentSheet Example",
                "PaymentSheetUITest",
                "PaymentSheetLocalizationScreenshotGenerator",
            ]),
            testAction: .targets(
                [
                    "PaymentSheetUITest",
                    "PaymentSheetLocalizationScreenshotGenerator",
                ],
                arguments: Arguments(
                    environment: [
                        "FB_REFERENCE_IMAGE_DIR": "$(SRCROOT)/../Tests/ReferenceImages",
                    ]
                ),
                expandVariableFromTarget: "PaymentSheet Example"
            ),
            runAction: .runAction(executable: "PaymentSheet Example")
        )
    ]
)
