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
            name: "AppClipExampleTests iOS",
            platform: .iOS,
            product: .uiTests,
            productName: "AppClipExampleTestsiOS",
            bundleId: "com.stripe.AppClipExampleTests",
            infoPlist: "Tests iOS/Info.plist",
            sources: "Tests iOS/*.swift",
            dependencies: [
                .target(name: "AppClipExample"),
            ],
            settings: .stripeTargetSettings(
                baseXcconfigFilePath: "BuildConfigurations/AppClipExampleTests-iOS"
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
        Target(
            name: "AppClipExampleClipTests",
            platform: .iOS,
            product: .unitTests,
            bundleId: "com.stripe.AppClipExample.AppClipExampleClipTests",
            infoPlist: "AppClipExampleClipTests/Info.plist",
            sources: "AppClipExampleClipTests/*.swift",
            dependencies: [
                .target(name: "AppClipExampleClip"),
            ],
            settings: .stripeTargetSettings(
                baseXcconfigFilePath: "BuildConfigurations/AppClipExampleClipTests"
            )
        ),
        Target(
            name: "AppClipExampleClipUITests",
            platform: .iOS,
            product: .uiTests,
            bundleId: "com.stripe.AppClipExample.AppClipExampleClipUITests",
            infoPlist: "AppClipExampleClipUITests/Info.plist",
            sources: "AppClipExampleClipUITests/*.swift",
            dependencies: [
                .target(name: "AppClipExampleClip"),
            ],
            settings: .stripeTargetSettings(
                baseXcconfigFilePath: "BuildConfigurations/AppClipExampleClipUITests"
            )
        ),
    ],
    schemes: [
        Scheme(
            name: "AppClipExample",
            buildAction: .buildAction(targets: [
                "AppClipExample",
                "AppClipExampleTests iOS",
            ]),
            testAction: .targets(["AppClipExampleTests iOS"]),
            runAction: .runAction(executable: "AppClipExample")
        ),
        Scheme(
            name: "AppClipExampleClip",
            buildAction: .buildAction(targets: [
                "AppClipExampleClip",
                "AppClipExampleClipTests",
                "AppClipExampleClipUITests",
            ]),
            testAction: .targets([
                "AppClipExampleClipTests",
                "AppClipExampleClipUITests",
            ]),
            runAction: .runAction(executable: "AppClipExampleClip")
        ),
    ]
)
