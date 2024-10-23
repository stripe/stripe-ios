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
@available(iOS 15, *)
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

    private(set) var webVC: ConnectComponentWebViewController!

    init(props: Props,
         componentManager: EmbeddedComponentManager,
         loadContent: Bool
    ) {
        super.init(nibName: nil, bundle: nil)
        webVC = ConnectComponentWebViewController(
            componentManager: componentManager,
            componentType: .onboarding,
            loadContent: loadContent
        ) {
            props
        } didFailLoadWithError: { [weak self] error in
            guard let self else { return }
            delegate?.accountOnboarding(self, didFailLoadWithError: error)
        }

        webVC.addMessageHandler(OnExitMessageHandler(didReceiveMessage: { [weak self] in
            guard let self else { return }
            self.delegate?.accountOnboardingDidExit(self)
        }))

        addChildAndPinView(webVC)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Delegate of an `AccountOnboardingViewController`
@_spi(PrivateBetaConnect)
@available(iOS 15, *)
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

@available(iOS 15, *)
public extension AccountOnboardingViewControllerDelegate {
    // Add default implementation of delegate methods to make them optional
    func accountOnboardingDidExit(_ accountOnboarding: AccountOnboardingViewController) { }
    func accountOnboarding(_ accountOnboarding: AccountOnboardingViewController,
                           didFailLoadWithError error: Error) { }
}
