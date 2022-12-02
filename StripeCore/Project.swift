import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.stripeFramework(
    name: "StripeCore",
    resources: "StripeCore/Resources/**",
    testUtilsOptions: .testOptions(
        resources: "StripeCoreTestUtils/Mock Files/**",
        settings: .settings(
            configurations: [
                .debug(
                    name: "Debug",
                    xcconfig:
                        "StripeCoreTestUtils/BuildConfigurations/StripeCoreTestUtils-Debug.xcconfig"
                ),
                .release(
                    name: "Release",
                    xcconfig:
                        "StripeCoreTestUtils/BuildConfigurations/StripeCoreTestUtils-Release.xcconfig"
                ),
            ],
            defaultSettings: .none
        ),
        includesSnapshots: true,
        usesStubs: true
    ),
    unitTestOptions: .testOptions(resources: "StripeCoreTests/Mock Files/**")
)
