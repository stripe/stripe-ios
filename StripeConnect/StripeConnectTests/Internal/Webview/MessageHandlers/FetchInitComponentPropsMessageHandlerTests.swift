//
//  FetchInitComponentPropsMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Mel Ludowise on 9/27/24.
//

@_spi(PrivateBetaConnect) @testable import StripeConnect
import XCTest

class FetchInitComponentPropsMessageHandlerTests: ScriptWebTestBase {

    @MainActor
    func testMessageSend() async throws {
        webView.addMessageReplyHandler(messageHandler: FetchInitComponentPropsMessageHandler {
            AccountOnboardingViewController.Props(
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
        })

        try await webView.evaluateMessageWithReply(name: "fetchInitComponentProps",
                                                   json: "{}",
                                                   expectedResponse: """
            {"setCollectionOptions":{"fields":"eventually_due","futureRequirements":"include"},"setFullTermsOfServiceUrl":"https:\\/\\/fullTermsOfServiceUrl.com","setPrivacyPolicyUrl":"https:\\/\\/privacyPolicyUrl.com","setRecipientTermsOfServiceUrl":"https:\\/\\/recipientTermsOfServiceUrl.com","setSkipTermsOfServiceCollection":true}
            """)
    }
}
