import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "IdentityVerification Example",
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
            settings: .stripeTargetSettings(
                baseXcconfigFilePath: "BuildConfigurations/IdentityVerification-Example"
            )
        ),
    ],
    schemes: [
        Scheme(
            name: "IdentityVerification Example",
            buildAction: .buildAction(targets: ["IdentityVerification Example"]),
            runAction: .runAction(executable: "IdentityVerification Example")
        ),
    ]
)
