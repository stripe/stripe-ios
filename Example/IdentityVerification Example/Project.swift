import ProjectDescription

let project = Project(
    name: "IdentityVerification Example",
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
            name: "IdentityVerification Example",
            platform: .iOS,
            product: .app,
            productName: "IdentityVerificationExample",
            bundleId: "com.stripe.IdentityVerification-Example",
            infoPlist: "IdentityVerification Example/Info.plist",
            sources: "IdentityVerification Example/*.swift",
            resources: "IdentityVerification Example/Resources/**",
            dependencies: [
                .project(target: "StripeCore", path: "//StripeCore"),
                .project(target: "StripeUICore", path: "//StripeUICore"),
                .project(target: "StripeIdentity", path: "//StripeIdentity"),
                .project(target: "StripeCameraCore", path: "//StripeCameraCore"),
            ],
            settings: .settings(base: [
                "TARGETED_DEVICE_FAMILY": "1,2",
                "CURRENT_PROJECT_VERSION": "1",
                "MARKETING_VERSION": "2.0",
                "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
                "ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS": true,
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
            ])
        ),
    ],
    schemes: [
        Scheme(
            name: "IdentityVerification Example",
            buildAction: .buildAction(targets: ["IdentityVerification Example"]),
            runAction: .runAction(executable: "IdentityVerification Example")
        )
    ]
)
