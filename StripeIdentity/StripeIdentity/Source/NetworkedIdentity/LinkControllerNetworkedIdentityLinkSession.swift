//
//  LinkControllerNetworkedIdentityLinkSession.swift
//  StripeIdentity
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentSheet
import UIKit

/// `NetworkedIdentityLinkSession` backed by `LinkController`. Only `authenticateWithLinkUI` presents Link UI.
///
/// Kept as a thin mapping because `LinkController` can't be faked; Identity's tests use `NetworkedIdentityLinkSession`
/// fakes instead.
@MainActor
final class LinkControllerNetworkedIdentityLinkSession: NetworkedIdentityLinkSession {
    enum SessionError: Error {
        case notConfigured
        case noLinkAccount
    }

    private var linkController: LinkController?

    func configure(merchantPublishableKey: String) async throws {
        linkController = try await LinkController.create(
            apiClient: STPAPIClient(publishableKey: merchantPublishableKey),
            mode: .setup,
            // #TODO - Networked Identity [NI-Contract]: add an Identity request surface once Link's sign-up and lookup
            // accept "ios_identity_product"; they reject it today. The crypto onramp surface is allowed to sign up.
            requestSurface: .cryptoOnramp
        )
    }

    func authenticateWithLinkUI(
        email: String?,
        phoneNumber: String?,
        mode: NetworkedIdentityMode,
        from viewController: UIViewController
    ) async throws -> NetworkedIdentityLinkAccount? {
        let controller = try configuredController()
        let content = LinkController.AuthenticationContent(
            title: String.Localized.continue_with_link,
            subtitle: mode == .save
                ? STPLocalizedString(
                    "Sign in or create an account to save ID.",
                    "Subtitle of the Link sign-in screen when saving the user's ID to Link"
                )
                : STPLocalizedString(
                    "Sign in to use a saved ID.",
                    "Subtitle of the Link sign-in screen when sharing an ID saved to Link"
                ),
            consentAction: .entered_phone_number_email_clicked_save_with_link_identity
        )
        let result: LinkController.AuthenticationResult = try await withCheckedThrowingContinuation { continuation in
            controller.presentForAuthentication(
                email: email,
                phoneNumber: phoneNumber,
                content: content,
                from: viewController
            ) {
                continuation.resume(with: $0)
            }
        }
        switch result {
        case .authenticated:
            return try currentAccount(of: controller)
        case .canceled:
            return nil
        }
    }

    private func configuredController() throws -> LinkController {
        guard let linkController else {
            throw SessionError.notConfigured
        }
        return linkController
    }

    private func currentAccount(of controller: LinkController) throws -> NetworkedIdentityLinkAccount {
        guard let account = controller.linkAccount else {
            throw SessionError.noLinkAccount
        }
        return NetworkedIdentityLinkAccount(
            email: account.email,
            isVerified: account.sessionState == .verified,
            credentials: account.linkSessionKey.flatMap {
                $0.isEmpty ? nil : NetworkedIdentityConsumerCredentials(linkSessionKey: $0)
            }
        )
    }
}
