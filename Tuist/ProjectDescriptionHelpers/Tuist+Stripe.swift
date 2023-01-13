import Foundation
import ProjectDescription

extension Project {
    /// Options for test targets inside Stripe frameworks.
    public struct TestOptions {
        public var resources: ResourceFileElements?
        public var dependencies: [TargetDependency] = []
        public var settings: Settings = .stripeTargetSettings(
            baseXcconfigFilePath: "//BuildConfigurations/StripeiOS Tests"
        )
        public var includesSnapshots: Bool = false
        public var usesMocks: Bool = false
        public var usesStubs: Bool = false

        /// Creates a `TestOptions` instance.
        ///
        /// - Parameters:
        ///   - resources: The resources for the target, can be `nil` if no resources needed.
        ///   - dependencies: Any dependencies necessary,
        ///     the target being tested will be added automatically.
        ///   - settings: Settings for the target, defaults to base settings for all tests,
        ///     only override if you need to specify custom settings.
        ///   - includesSnapshots: Whether this target includes snapshot tests.
        ///     If `true`, the iOSSnapshotTestCase package will be linked and an environment
        ///     variable to the default location of reference images will be added.
        ///   - usesMocks: Whether the tests in this target use mocks.
        ///     If `true`, the OCMock package will be linked.
        ///   - usesStubs: Whether the tests in this target use stubs.
        ///     If `true`, the OHHTTPStubs package will be linked.
        /// - Returns: A `TestOptions` instance.
        public static func testOptions(
            resources: ResourceFileElements? = nil,
            dependencies: [TargetDependency] = [],
            settings: Settings = .stripeTargetSettings(
                baseXcconfigFilePath: "//BuildConfigurations/StripeiOS Tests"
            ),
            includesSnapshots: Bool = false,
            usesMocks: Bool = false,
            usesStubs: Bool = false
        ) -> TestOptions {
            return TestOptions(
                resources: resources,
                dependencies: dependencies,
                settings: settings,
                includesSnapshots: includesSnapshots,
                usesMocks: usesMocks,
                usesStubs: usesStubs
            )
        }
    }

    /// Utility to create a `Project` that follows the conventions of all Stripe frameworks.
    ///
    /// The `Project` will include:
    /// - A framework `Target` with same name as the project.
    /// - A framework `Target` if `testUtilsOptions` is included, named (`name`)TestUtils.
    /// - A unit tests `Target` if `unitTestOptions` is included, named (`name`)Tests.
    /// - A ui tests `Target` if `uiTestOptions` is included, named (`name`)UITests.
    ///
    /// The files for each target **must** be in specific locations:
    /// - Info.plist: targetName/Info.plist
    /// - Sources:
    ///   - Main target: targetName/Source/
    ///   - Test targets: targetName/
    /// - Public header: targetName/targetName.h
    ///
    /// A `Scheme` with the same name as the `Project` will be created, it will include the
    /// main target in the build action and the test targets in the test action.
    /// If `testUtilsOptions` is included, a second `Scheme` will be included, with only the
    /// test utils target in the build action.
    ///
    /// - Parameters:
    ///   - name: The name that will be used for the `Project`, main `Target` and `Scheme`.
    ///   - packages: Any SPM packages needed in this project.
    ///     Note that the iOSSnapshotTestCase, OCMock and OHHTTPStubs packages will be added
    ///     automatically if they are required by any tests, so they shouldn't be included.
    ///   - projectSettings: Settings used at project level. Only specify if you need to provide
    ///     specific properties for this and only this project, if you need to add/change a setting
    ///     check if it makes sense to change it for all frameworks too.
    ///   - targetSettings: Settings used at target level. Only specify if you need to provide
    ///     specific properties for this and only this target, if you need to add/change a setting
    ///     check if it makes sense to change it for all frameworks too.
    ///   - resources: Any resources needed by the framework.
    ///   - dependencies: Any dependencies required by the main target.
    ///   - testUtilsOptions: Options for the test utils target if one is needed.
    ///   - unitTestOptions: Options for the unit tests target if one is needed.
    ///   - uiTestOptions: Options for the ui tests target if one is needed.
    /// - Returns: A `Project` configured for a Stripe framework.
    public static func stripeFramework(
        name: String,
        packages: [Package] = [],
        projectSettings: Settings = .settings(
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
        targetSettings: Settings = .stripeTargetSettings(
            baseXcconfigFilePath: "//BuildConfigurations/StripeiOS"
        ),
        resources: ResourceFileElements? = nil,
        dependencies: [TargetDependency] = [],
        testUtilsOptions: TestOptions? = nil,
        unitTestOptions: TestOptions? = nil,
        uiTestOptions: TestOptions? = nil
    ) -> Project {
        return Project(
            name: name,
            options: .options(
                automaticSchemesOptions: .disabled,
                disableBundleAccessors: true,
                disableSynthesizedResourceAccessors: true
            ),
            packages: makePackages(
                testUtilsOptions: testUtilsOptions,
                unitTestOptions: unitTestOptions,
                uiTestOptions: uiTestOptions
            ) + packages,
            settings: projectSettings,
            targets: makeTargets(
                name: name,
                targetSettings: targetSettings,
                dependencies: dependencies,
                resources: resources,
                testUtilsOptions: testUtilsOptions,
                unitTestOptions: unitTestOptions,
                uiTestOptions: uiTestOptions
            ),
            schemes: makeSchemes(
                name: name,
                testUtilsOptions: testUtilsOptions,
                unitTestOptions: unitTestOptions,
                uiTestOptions: uiTestOptions
            )
        )
    }

    private static func makePackages(
        testUtilsOptions: TestOptions?,
        unitTestOptions: TestOptions?,
        uiTestOptions: TestOptions?
    ) -> [Package] {
        var packages = [Package]()
        if testUtilsOptions?.includesSnapshots ?? false
            || unitTestOptions?.includesSnapshots ?? false
            || uiTestOptions?.includesSnapshots ?? false
        {
            packages.append(
                .remote(
                    url: "https://github.com/uber/ios-snapshot-test-case",
                    requirement: .upToNextMajor(from: "8.0.0")
                )
            )
        }
        if testUtilsOptions?.usesMocks ?? false
            || unitTestOptions?.usesMocks ?? false
            || uiTestOptions?.usesMocks ?? false
        {
            packages.append(
                .remote(url: "https://github.com/erikdoe/ocmock", requirement: .branch("master"))
            )
        }
        if testUtilsOptions?.usesStubs ?? false
            || unitTestOptions?.usesStubs ?? false
            || uiTestOptions?.usesStubs ?? false
        {
            packages.append(
                .remote(
                    url: "https://github.com/eurias-stripe/OHHTTPStubs",
                    requirement: .branch("master")
                )
            )
        }
        return packages
    }

    private static func makeTargets(
        name: String,
        targetSettings: Settings,
        dependencies: [TargetDependency],
        resources: ResourceFileElements?,
        testUtilsOptions: TestOptions?,
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
                sources: [
                    "\(name)/Source/**/*.swift",
                    "\(name)/*.docc",
                ],
                resources: resources,
                headers: .headers(
                    public: "\(name)/\(name).h"
                ),
                dependencies: dependencies,
                settings: targetSettings
            )
        )
        if let testUtilsOptions = testUtilsOptions {
            targets.append(
                Target(
                    name: "\(name)TestUtils",
                    platform: .iOS,
                    product: .framework,
                    bundleId: "com.stripe.\(name)TestUtils",
                    infoPlist: "\(name)TestUtils/Info.plist",
                    sources: "\(name)TestUtils/**/*.swift",
                    resources: testUtilsOptions.resources,
                    headers: .headers(
                        public: "\(name)TestUtils/\(name)TestUtils.h"
                    ),
                    dependencies: makeTestDependencies(name: name, testOptions: testUtilsOptions),
                    settings: testUtilsOptions.settings
                )
            )
        }
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
                    dependencies: makeTestDependencies(
                        name: name,
                        includeUtils: testUtilsOptions != nil,
                        testOptions: unitTestOptions
                    ),
                    settings: unitTestOptions.settings
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
                    dependencies: makeTestDependencies(
                        name: name,
                        includeUtils: testUtilsOptions != nil,
                        testOptions: uiTestOptions
                    ),
                    settings: uiTestOptions.settings
                )
            )
        }
        return targets
    }

    private static func makeTestDependencies(
        name: String,
        includeUtils: Bool = false,
        testOptions: TestOptions
    ) -> [TargetDependency] {
        var dependencies: [TargetDependency] = [
            .xctest,
            .target(name: name),
        ]

        if includeUtils {
            dependencies.append(.target(name: "\(name)TestUtils"))
        }
        if testOptions.includesSnapshots {
            dependencies.append(.package(product: "iOSSnapshotTestCase"))
        }
        if testOptions.usesMocks {
            dependencies.append(.package(product: "OCMock"))
        }
        if testOptions.usesStubs {
            dependencies += [
                .package(product: "OHHTTPStubs"),
                .package(product: "OHHTTPStubsSwift"),
            ]
        }
        return dependencies + testOptions.dependencies
    }

    private static func makeSchemes(
        name: String,
        testUtilsOptions: TestOptions?,
        unitTestOptions: TestOptions?,
        uiTestOptions: TestOptions?
    ) -> [Scheme] {
        var schemes = [Scheme]()
        schemes.append(
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
                                    "$(SRCROOT)/../Tests/ReferenceImages",
                            ]
                        ) : nil,
                    expandVariableFromTarget: "\(name)"
                )
            )
        )
        if testUtilsOptions != nil {
            schemes.append(
                Scheme(
                    name: "\(name)TestUtils",
                    buildAction: .buildAction(targets: ["\(name)TestUtils"])
                )
            )
        }
        return schemes
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

extension Settings {
    enum BuildSetting: String {
        case codeSignIdentity = "CODE_SIGN_IDENTITY"
        case developmentTeam = "DEVELOPMENT_TEAM"
    }

    /// Utility to generate settings for a Stripe target.
    ///
    /// It will add the `CODE_SIGN_IDENTITY` and `DEVELOPMENT_TEAM` build settings to the target
    /// based on the `TUIST_CODE_SIGN_IDENTITY` and `TUIST_DEVELOPMENT_TEAM` environment variables.
    /// This is so these settings don't have to be specified on config files, but can be easily
    /// added at generation time during development.
    /// It will also generate the configuration from xcconfig files according to the base file path
    /// given, with this format:
    ///
    /// `\(baseXcconfigFilePath)-\(configuration).xcconfig`
    /// i.e.
    /// `\(baseXcconfiFilePath)-Debug.xcconfig`
    ///
    /// - Note: Don't use for project level settings.
    ///
    /// - Parameters:
    ///   - base: Any base settings. Use sparringly, prefer to use an xcconfig file.
    ///   - baseXcconfigFilePath: The xcconfig file path prefix. The final file paths will be
    ///     generated as follows:
    ///     `\(baseXcconfigFilePath)-\(configuration).xcconfig`
    ///     i.e.
    ///     `\(baseXcconfiFilePath)-Debug.xcconfig`
    /// - Returns: `Settings` for a Stripe target.
    public static func stripeTargetSettings(
        base: SettingsDictionary = [:],
        baseXcconfigFilePath: String
    ) -> Settings {
        var baseSettings = base
        if case let .string(codeSignIdentity) = Environment.codeSignIdentity {
            baseSettings[BuildSetting.codeSignIdentity.rawValue] = .string(codeSignIdentity)
        }
        if case let .string(developmentTeam) = Environment.developmentTeam {
            baseSettings[BuildSetting.developmentTeam.rawValue] = .string(developmentTeam)
        }

        return .settings(
            base: baseSettings,
            configurations: [
                .debug(
                    name: "Debug",
                    xcconfig: "\(baseXcconfigFilePath)-Debug.xcconfig"
                ),
                .release(
                    name: "Release",
                    xcconfig: "\(baseXcconfigFilePath)-Release.xcconfig"
                ),
            ],
            defaultSettings: .none
        )
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
