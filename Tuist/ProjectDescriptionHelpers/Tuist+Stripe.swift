import Foundation
import ProjectDescription

extension Project {
    public struct TestOptions {
        public var resources: ResourceFileElements? = nil
        public var dependencies: [TargetDependency] = []
        public var includesSnapshots: Bool = false

        public static func testOptions(
            resources: ResourceFileElements? = nil,
            dependencies: [TargetDependency] = [],
            includesSnapshots: Bool = false
        ) -> TestOptions {
            return TestOptions(
                resources: resources,
                dependencies: dependencies,
                includesSnapshots: includesSnapshots
            )
        }
    }

    public static func stripeFramework(
        name: String,
        packages: [Package] = [],
        targetSettingsOverride: Settings? = nil,
        resources: ResourceFileElements? = nil,
        dependencies: [TargetDependency] = [],
        additionalTargets: [Target] = [],
        additionalSchemes: [Scheme] = [],
        unitTestOptions: TestOptions? = nil,
        uiTestOptions: TestOptions? = nil
    ) -> Project {
        return Project(
            name: name,
            options: .options(automaticSchemesOptions: .disabled),
            packages: packages,
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
                ]
            ),
            targets: makeTargets(
                name: name,
                targetSettingsOverride: targetSettingsOverride,
                dependencies: dependencies,
                resources: resources,
                unitTestOptions: unitTestOptions,
                uiTestOptions: uiTestOptions
            ) + additionalTargets,
            schemes: makeSchemes(
                name: name,
                unitTestOptions: unitTestOptions,
                uiTestOptions: uiTestOptions
            ) + additionalSchemes,
            resourceSynthesizers: []
        )
    }

    private static func makeTargets(
        name: String,
        targetSettingsOverride: Settings?,
        dependencies: [TargetDependency],
        resources: ResourceFileElements?,
        unitTestOptions: TestOptions?,
        uiTestOptions: TestOptions?
    ) -> [Target] {
        var targets = [Target]()
        targets.append(
            Target(
                name: name,
                platform: .iOS,
                product: .framework,
                bundleId: "com.stripe.\(name.casedToDashed)",
                infoPlist: "\(name)/Info.plist",
                sources: "\(name)/Source/**/*.swift",
                resources: resources,
                headers: .headers(
                    public: "\(name)/\(name).h"
                ),
                dependencies: dependencies,
                settings: targetSettingsOverride
                    ?? .settings(
                        configurations: [
                            .debug(
                                name: "Debug",
                                xcconfig: "//BuildConfigurations/StripeiOS-Debug.xcconfig"
                            ),
                            .release(
                                name: "Release",
                                xcconfig: "//BuildConfigurations/StripeiOS-Release.xcconfig"
                            ),
                        ]
                    )
            )
        )
        if let unitTestOptions = unitTestOptions {
            targets.append(
                Target(
                    name: "\(name)Tests",
                    platform: .iOS,
                    product: .unitTests,
                    bundleId: "com.stripe.\(name)Tests",
                    infoPlist: "\(name)Tests/Info.plist",
                    sources: "\(name)Tests/**/*.swift",
                    resources: unitTestOptions.resources,
                    headers: .headers(
                        public: "\(name)Tests/\(name)Tests.h"
                    ),
                    dependencies: [
                        .xctest,
                        .target(name: name),
                    ] + unitTestOptions.dependencies,
                    settings: .settings(configurations: [
                        .debug(
                            name: "Debug",
                            xcconfig: "//BuildConfigurations/StripeiOS Tests-Debug.xcconfig"
                        ),
                        .release(
                            name: "Release",
                            xcconfig:
                                "//BuildConfigurations/StripeiOS Tests-Release.xcconfig"
                        ),
                    ])
                )
            )
        }
        if let uiTestOptions = uiTestOptions {
            targets.append(
                Target(
                    name: "\(name)UITests",
                    platform: .iOS,
                    product: .uiTests,
                    bundleId: "com.stripe.\(name)UITests",
                    infoPlist: "\(name)UITests/Info.plist",
                    sources: "\(name)UITests/**/*.swift",
                    resources: uiTestOptions.resources,
                    headers: .headers(
                        public: "\(name)UITests/\(name)UITests.h"
                    ),
                    dependencies: [
                        .xctest,
                        .target(name: name),
                    ] + uiTestOptions.dependencies,
                    settings: .settings(configurations: [
                        .debug(
                            name: "Debug",
                            xcconfig: "//BuildConfigurations/StripeiOS Tests-Debug.xcconfig"
                        ),
                        .release(
                            name: "Release",
                            xcconfig:
                                "//BuildConfigurations/StripeiOS Tests-Release.xcconfig"
                        ),
                    ])
                )
            )
        }
        return targets
    }

    private static func makeSchemes(
        name: String,
        unitTestOptions: TestOptions?,
        uiTestOptions: TestOptions?
    ) -> [Scheme] {
        return [
            Scheme(
                name: name,
                buildAction: .buildAction(targets: ["\(name)"]),
                testAction: .targets(
                    makeTestActionTargets(
                        name: name,
                        unitTestOptions: unitTestOptions,
                        uiTestOptions: uiTestOptions
                    ),
                    arguments: unitTestOptions?.includesSnapshots ?? false
                        || uiTestOptions?.includesSnapshots ?? false
                        ? Arguments(
                            environment: [
                                "FB_REFERENCE_IMAGE_DIR":
                                    "$(SRCROOT)/../Tests/ReferenceImages"
                            ]
                        ) : nil,
                    expandVariableFromTarget: "\(name)"
                )
            )
        ]
    }

    private static func makeTestActionTargets(
        name: String,
        unitTestOptions: TestOptions?,
        uiTestOptions: TestOptions?
    ) -> [TestableTarget] {
        var targets = [TestableTarget]()
        if unitTestOptions != nil {
            targets.append("\(name)Tests")
        }
        if uiTestOptions != nil {
            targets.append("\(name)UITests")
        }
        return targets
    }
}

extension String {
    // Based on https://gist.github.com/dmsl1805/ad9a14b127d0409cf9621dc13d237457.
    var casedToDashed: String {
        let acronymPattern = "([A-Z]+)([A-Z][a-z]|[0-9])"
        let normalPattern = "([a-z0-9])([A-Z])"
        return processRegex(pattern: acronymPattern)?
            .processRegex(pattern: normalPattern)?
            .lowercased()
            ?? self.lowercased()
    }

    func processRegex(pattern: String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(
            in: self,
            options: [],
            range: range,
            withTemplate: "$1-$2"
        )
    }
}
