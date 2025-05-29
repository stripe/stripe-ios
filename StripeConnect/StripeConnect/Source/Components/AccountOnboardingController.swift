//
//  AccountOnboardingController.swift
//  StripeConnect
//
//  Created by Chris Mays on 9/17/24.
//

import UIKit

/// Delegate of an `AccountOnboardingController`
@available(iOS 15, *)
public protocol AccountOnboardingControllerDelegate: AnyObject {
    /**
     The connected account has exited the onboarding process. When this triggers, retrieve account details to check the status of
     details_submitted, charges_enabled, payouts_enabled, and other capabilities. If all required capabilities are enabled, you can take
     the account to the next step of your flow.
     - Parameters:
     - accountOnboarding: The account onboarding controller associated with this onboarding experience
     */
    func accountOnboardingDidExit(_ accountOnboarding: AccountOnboardingController)

    /**
     Triggered when an error occurs loading the account onboarding component
     - Parameters:
     - accountOnboarding: The account onboarding component that errored when loading
     - error: The error that occurred when loading the component
     */
    func accountOnboarding(_ accountOnboarding: AccountOnboardingController,
                           didFailLoadWithError error: Error)

}

@available(iOS 15, *)
public extension AccountOnboardingControllerDelegate {
    // Add default implementation of delegate methods to make them optional
    func accountOnboardingDidExit(_ accountOnboarding: AccountOnboardingController) { }

    func accountOnboarding(_ accountOnboarding: AccountOnboardingController,
                           didFailLoadWithError error: Error) { }
}

/// A view controller representing an account-onboarding component
/// - Seealso: [Account onboarding component documentation](https://docs.stripe.com/connect/supported-embedded-components/account-onboarding?platform=ios)
@available(iOS 15, *)
public final class AccountOnboardingController {
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

    // The controller should exist for at least the length that the ViewController is presented.
    // Delegate callbacks remove the need for the implementor to hold onto the controller
    // so we set retainedSelf on present, and unset it when the VC is dismissed.
    var retainedSelf: AccountOnboardingController?

    /// Delegate that receives callbacks for this component
    public weak var delegate: AccountOnboardingControllerDelegate?

    /// Sets the title for the onboarding experience
    public var title: String? {
        get {
            webVC.title
        }
        set {
            webVC.title = newValue
        }
    }

    private(set) var webVC: ConnectComponentWebViewController!

    init(props: Props,
         componentManager: EmbeddedComponentManager,
         loadContent: Bool,
         analyticsClientFactory: ComponentAnalyticsClientFactory
    ) {
        webVC = ConnectComponentWebViewController(
            componentManager: componentManager,
            componentType: .onboarding,
            loadContent: loadContent,
            analyticsClientFactory: analyticsClientFactory
        ) {
            props
        } didFailLoadWithError: { [weak self] error in
            guard let self else { return }
            self.delegate?.accountOnboarding(self, didFailLoadWithError: error)
        }

        webVC.addMessageHandler(OnExitMessageHandler(didReceiveMessage: { [weak self] in
            guard let self else { return }
            self.dismiss()
        }))
    }

    /// Presents the onboarding experience.
    public func present(from viewController: UIViewController, animated: Bool = true) {
        let navController = UINavigationController(rootViewController: webVC)
        navController.navigationBar.prefersLargeTitles = false
        navController.modalPresentationStyle = .fullScreen
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        navController.navigationBar.standardAppearance = appearance
        navController.navigationBar.scrollEdgeAppearance = appearance

        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .done,
            target: self,
            action: #selector(closeButtonTapped(_:))
        )
        closeButton.accessibilityIdentifier = "closeButton"

        webVC.navigationItem.rightBarButtonItem = closeButton
        viewController.present(navController, animated: animated)
        retainedSelf = self
        webVC.onDismiss = { [weak self] in
            guard let self else { return }
            self.delegate?.accountOnboardingDidExit(self)
            self.retainedSelf = nil
        }
    }

    /// Dismisses the currently presented onboarding experience.
    /// No-Ops if not presented.
    func dismiss(animated: Bool = true) {
        webVC.dismiss(animated: animated)
    }

    @objc
    func closeButtonTapped(_ sender: UIBarButtonItem) {
        Task { @MainActor in
            do {
                try await self.webVC.sendMessageAsync(MobileInputReceivedSender())
            } catch {
                self.dismiss()
            }
        }
    }
}
