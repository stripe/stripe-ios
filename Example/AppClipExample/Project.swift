import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "AppClipExample",
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
            name: "AppClipExample",
            platform: .iOS,
            product: .app,
            bundleId: "com.stripe.AppClipExample",
            infoPlist: "Info.plist",
            sources: "Shared/*.swift",
            resources: "Shared/Assets.xcassets",
            entitlements: "AppClipExample (iOS).entitlements",
            dependencies: [
                .target(name: "AppClipExampleClip"),
                .project(target: "StripeCore", path: "//StripeCore"),
                .project(target: "StripeApplePay", path: "//StripeApplePay"),
            ],
            settings: .stripeTargetSettings(
                baseXcconfigFilePath: "BuildConfigurations/AppClipExample"
            )
        ),
        Target(
            name: "AppClipExampleClip",
            platform: .iOS,
            product: .appClip,
            bundleId: "com.stripe.AppClipExample.Clip",
            infoPlist: "Info.plist",
            sources: "Shared/*.swift",
            resources: [
                "AppClipExampleClip/Assets.xcassets",
                "AppClipExampleClip/Preview Content/**",
            ],
            entitlements: "AppClipExampleClip/AppClipExampleClip.entitlements",
            dependencies: [
                .project(target: "StripeCore", path: "//StripeCore"),
                .project(target: "StripeApplePay", path: "//StripeApplePay"),
            ],
            settings: .stripeTargetSettings(
                baseXcconfigFilePath: "BuildConfigurations/AppClipExampleClip"
            )
        ),
    ],
    schemes: [
        Scheme(
            name: "AppClipExample",
            buildAction: .buildAction(targets: ["AppClipExample"]),
            runAction: .runAction(executable: "AppClipExample")
        ),
        Scheme(
            name: "AppClipExampleClip",
            buildAction: .buildAction(targets: ["AppClipExampleClip"]),
            runAction: .runAction(executable: "AppClipExampleClip")
        )
    ]
)

