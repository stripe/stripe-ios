//
//  AccountOnboardingViewController.swift
//  StripeConnect
//
//  Created by Chris Mays on 9/17/24.
//

import UIKit

/// A view controller representing an account-onboarding component
/// - Seealso: https://docs.stripe.com/connect/supported-embedded-components/account-onboarding
@_spi(PrivateBetaConnect)
public class AccountOnboardingViewController: UIViewController {

    struct Props: Encodable {
        let fullTermsOfServiceUrl: URL?
        let recipientTermsOfServiceUrl: URL?
        let privacyPolicyUrl: URL?
        let skipTermsOfServiceCollection: Bool?
        let collectionOptions: AccountCollectionOptions

        // Used in FetchInitComponentPropsMessageHandler
        // Each property key should match its JS setter name
        enum CodingKeys: String, CodingKey {
            case fullTermsOfServiceUrl = "setFullTermsOfServiceUrl"
            case recipientTermsOfServiceUrl = "setRecipientTermsOfServiceUrl"
            case privacyPolicyUrl = "setPrivacyPolicyUrl"
            case skipTermsOfServiceCollection = "setSkipTermsOfServiceCollection"
            case collectionOptions = "setCollectionOptions"
        }
    }

    /// Delegate that receives callbacks for this component
    public weak var delegate: AccountOnboardingViewControllerDelegate?

    let webView: ConnectComponentWebView

    init(props: Props,
         componentManager: EmbeddedComponentManager,
         // Test Only
         loadContent: Bool = true
    ) {
        webView = ConnectComponentWebView(
            componentManager: componentManager,
            componentType: .onboarding(props),
            loadContent: loadContent
        )
        super.init(nibName: nil, bundle: nil)

        webView.addMessageHandler(OnLoadErrorMessageHandler { [weak self] value in
            guard let self else { return }
            self.delegate?.accountOnboarding(self, didFailLoadWithError: value.error.connectEmbedError)
        })

        webView.addMessageHandler(OnExitMessageHandler(didReceiveMessage: { [weak self] in
            guard let self else { return }
            self.delegate?.accountOnboardingDidExit(self)
        }))

        webView.presentPopup = { [weak self] vc in
            self?.present(vc, animated: true)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = webView
    }
}

/// Delegate of an `AccountOnboardingViewController`
@_spi(PrivateBetaConnect)
public protocol AccountOnboardingViewControllerDelegate: AnyObject {
    /**
     The connected account has exited the onboarding process
     - Parameters accountOnboarding: The account onboarding component that the account exited
     */
    func accountOnboardingDidExit(_ accountOnboarding: AccountOnboardingViewController)

    /**
     Triggered when an error occurs loading the account onboarding component
     - Parameters:
       - accountOnboarding: The account onboarding component that errored when loading
       - error: The error that occurred when loading the component
     */
    func accountOnboarding(_ accountOnboarding: AccountOnboardingViewController,
                           didFailLoadWithError error: Error)

}

public extension AccountOnboardingViewControllerDelegate {
    // Add default implementation of delegate methods to make them optional
    func accountOnboardingDidExit(_ accountOnboarding: AccountOnboardingViewController) { }
    func accountOnboarding(_ accountOnboarding: AccountOnboardingViewController,
                           didFailLoadWithError error: Error) { }
}
