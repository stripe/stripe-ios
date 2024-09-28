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
        let componentType = ComponentType.onboarding(.init(
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
        ))
        webView.addMessageReplyHandler(messageHandler: FetchInitComponentPropsMessageHandler(componentType: componentType))

        try await webView.evaluateMessageWithReply(name: "fetchInitComponentProps",
                                                   json: "{}",
                                                   expectedResponse: """
            {"setCollectionOptions":{"fields":"eventually_due","futureRequirements":"include"},"setFullTermsOfServiceUrl":"https:\\/\\/fullTermsOfServiceUrl.com","setPrivacyPolicyUrl":"https:\\/\\/privacyPolicyUrl.com","setRecipientTermsOfServiceUrl":"https:\\/\\/recipientTermsOfServiceUrl.com","setSkipTermsOfServiceCollection":true}
            """)
    }
}
