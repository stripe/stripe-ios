import ProjectDescription

let allFrameworksTargets: [TargetReference] = [
    .project(path: "Stripe", target: "StripeiOS"),
    .project(path: "StripeApplePay", target: "StripeApplePay"),
    .project(path: "StripeCameraCore", target: "StripeCameraCore"),
    .project(path: "StripeCardScan", target: "StripeCardScan"),
    .project(path: "StripeCore", target: "StripeCore"),
    .project(path: "StripePayments", target: "StripePayments"),
    .project(path: "StripePaymentsUI", target: "StripePaymentsUI"),
    .project(path: "StripePaymentSheet", target: "StripePaymentSheet"),
    .project(path: "StripeUICore", target: "StripeUICore"),
    .project(path: "StripeIdentity", target: "StripeIdentity"),
    .project(path: "StripeFinancialConnections", target: "StripeFinancialConnections"),
    .project(path: "Stripe3DS2", target: "Stripe3DS2"),
    .project(path: "StripeLinkCore", target: "StripeLinkCore"),
]

let allTestsTargets: [TestableTarget] = {
    allFrameworksTargets.map { .init(target: .init(projectPath: $0.projectPath, target: "\($0.targetName)Tests")) } 
    + [TestableTarget(target: .init(projectPath: "Stripe3DS2", target: "Stripe3DS2DemoUITests"))]
}()

let workspace = Workspace(
    name: "Stripe",
    projects: [
        "Stripe",
        "Stripe3DS2",
        "StripeApplePay",
        "StripeCameraCore",
        "StripeCardScan",
        "StripeCore",
        "StripeFinancialConnections",
        "StripeIdentity",
        "StripeLinkCore",
        "StripePayments",
        "StripePaymentsUI",
        "StripePaymentSheet",
        "StripeUICore",
        "Testers/IntegrationTester",
        "Example/UI Examples",
        "Example/FinancialConnections Example",
        "Example/CardImageVerification Example",
        "Example/IdentityVerification Example",
        "Example/Non-Card Payment Examples",
        "Example/Basic Integration",
        "Example/PaymentSheet Example",
        "Example/AppClipExample",
    ],
    schemes: [
        Scheme(
            name: "AllStripeFrameworks",
            buildAction: .buildAction(targets: allFrameworksTargets),
            testAction: .targets(allTestsTargets,
                                 arguments: Arguments(
                                    environment: [
                                        "FB_REFERENCE_IMAGE_DIR":
                                            "$(SOURCE_ROOT)/../Tests/ReferenceImages",
                                    ]
                                 ),
                                 expandVariableFromTarget: allFrameworksTargets.first
                                )
        ),
        Scheme(
            name: "AllStripeFrameworks-RecordMode",
            buildAction: .buildAction(targets: allFrameworksTargets),
            testAction: .targets(allTestsTargets,
                                 arguments: Arguments(
                                    environment: [
                                        "FB_REFERENCE_IMAGE_DIR":
                                            "$(SOURCE_ROOT)/../Tests/ReferenceImages",
                                        "STP_RECORD_SNAPSHOTS": "true"
                                    ]
                                 ),
                                 expandVariableFromTarget: allFrameworksTargets.first
                                )
        ),
        Scheme(
            name: "AllStripeFrameworksCatalyst",
            buildAction: .buildAction(targets: [
                .project(path: "Stripe", target: "StripeiOS"),
                .project(path: "StripeApplePay", target: "StripeApplePay"),
                .project(path: "StripeCore", target: "StripeCore"),
                .project(path: "StripePayments", target: "StripePayments"),
                .project(path: "StripePaymentsUI", target: "StripePaymentsUI"),
                .project(path: "StripePaymentSheet", target: "StripePaymentSheet"),
                .project(path: "StripeUICore", target: "StripeUICore"),
                .project(path: "Stripe3DS2", target: "Stripe3DS2"),
                .project(path: "StripeLinkCore", target: "StripeLinkCore"),
            ])
        ),
    ],
    additionalFiles: [
        "Package.swift",
    ],
    generationOptions: .options(
        autogeneratedWorkspaceSchemes: .disabled
    )
)
