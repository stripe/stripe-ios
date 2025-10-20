//
//  FetchInitComponentPropsMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Mel Ludowise on 9/27/24.
//

@_spi(DashboardOnly) @testable import StripeConnect
import XCTest

class FetchInitComponentPropsMessageHandlerTests: ScriptWebTestBase {

    @MainActor
    func testMessageSend() async throws {
        var registeredSupplementalFunctions: SupplementalFunctions?

        webView.addMessageReplyHandler(messageHandler: FetchInitComponentPropsMessageHandler {
            AccountOnboardingController.Props(
                fullTermsOfServiceUrl: URL(string: "https://fullTermsOfServiceUrl.com")!,
                recipientTermsOfServiceUrl: URL(string: "https://recipientTermsOfServiceUrl.com")!,
                privacyPolicyUrl: URL(string: "https://privacyPolicyUrl.com")!,
                skipTermsOfServiceCollection: true,
                collectionOptions: {
                    var collectionOptions = AccountCollectionOptions()
                    collectionOptions.fields = .eventuallyDue
                    collectionOptions.futureRequirements = .include
                    return collectionOptions
                }()
            )
        } registerSupplementalFunctions: { fns in
            registeredSupplementalFunctions = fns
        })

        try await webView.evaluateMessageWithReply(name: "fetchInitComponentProps",
                                                   json: "{}",
                                                   expectedResponse: """
            {"setCollectionOptions":{"fields":"eventually_due","futureRequirements":"include"},"setFullTermsOfServiceUrl":"https:\\/\\/fullTermsOfServiceUrl.com","setPrivacyPolicyUrl":"https:\\/\\/privacyPolicyUrl.com","setRecipientTermsOfServiceUrl":"https:\\/\\/recipientTermsOfServiceUrl.com","setSkipTermsOfServiceCollection":true}
            """)

        XCTAssertNil(registeredSupplementalFunctions)
    }

    @MainActor
    func testMessageSend_registersSupplementalFunctions() async throws {
        struct Props: HasSupplementalFunctions {
            let supplementalFunctions: SupplementalFunctions

            enum CodingKeys: CodingKey {}
        }

        let supplementalFunctions: SupplementalFunctions = .init(handleCheckScanSubmitted: { _ in
            return HandleCheckScanSubmittedReturnValue()
        })
        var registeredSupplementalFunctions: SupplementalFunctions?

        webView.addMessageReplyHandler(messageHandler: FetchInitComponentPropsMessageHandler {
            Props(supplementalFunctions: supplementalFunctions)
        } registerSupplementalFunctions: { fns in
            registeredSupplementalFunctions = fns
        })

        try await webView.evaluateMessageWithReply(name: "fetchInitComponentProps",
                                                   json: "{}",
                                                   expectedResponse: """
            {"setHandleCheckScanSubmitted":true}
            """)

        XCTAssertTrue(registeredSupplementalFunctions === supplementalFunctions)
    }
}
