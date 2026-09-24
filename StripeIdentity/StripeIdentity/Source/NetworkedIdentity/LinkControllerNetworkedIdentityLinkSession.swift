//
//  LinkControllerNetworkedIdentityLinkSession.swift
//  StripeIdentity
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentSheet
import UIKit

/// `NetworkedIdentityLinkSession` backed by `LinkController`. Only `authenticateWithLinkUI` presents Link UI.
///
/// Kept as a thin mapping: `LinkController` can't be faked, so behavior is tested through
/// `NetworkedIdentityLinkSession` fakes and Link's own tests.
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
            // #TODO - Networked Identity [NI-Contract]: use `.identity` once "ios_identity_product" is deployed.
            // The crypto onramp surface is borrowed meanwhile because it is allowed to sign up.
            requestSurface: .cryptoOnramp
        )
    }

    func restore(credentials: NetworkedIdentityConsumerCredentials) async throws -> NetworkedIdentityLinkAccount {
        let controller = try configuredController()
        try await controller.restoreConsumerSession(
            consumerSessionClientSecret: credentials.sessionClientSecret,
            consumerPublishableKey: credentials.publishableKey
        )
        return try currentAccount(of: controller)
    }

    func lookup(email: String) async throws -> NetworkedIdentityLinkAccount? {
        let controller = try configuredController()
        guard try await controller.lookupConsumer(with: email) else {
            return nil
        }
        return try currentAccount(of: controller)
    }

    func startVerification(isResend: Bool) async throws -> NetworkedIdentityLinkAccount {
        let controller = try configuredController()
        try await controller.startVerification(isResendingSmsCode: isResend)
        return try currentAccount(of: controller)
    }

    func confirmVerification(code: String) async throws -> NetworkedIdentityLinkAccount {
        let controller = try configuredController()
        try await controller.confirmVerification(code: code)
        return try currentAccount(of: controller)
    }

    func signUp(
        email: String,
        phoneNumber: String,
        country: String,
        name: String?
    ) async throws -> NetworkedIdentityLinkAccount {
        let controller = try configuredController()
        // LinkController requires a lookup before registering, to hold the email being signed up.
        _ = try await controller.lookupConsumer(with: email)
        try await controller.registerLinkUser(
            fullName: name,
            phone: phoneNumber,
            country: country,
            consentAction: .entered_phone_number_email_clicked_save_with_link_identity
        )
        return try currentAccount(of: controller)
    }

    func logOut() async throws {
        try await configuredController().logOut()
    }

    func authenticateWithLinkUI(
        email: String?,
        mode: NetworkedIdentityMode,
        from viewController: UIViewController
    ) async throws -> NetworkedIdentityLinkAccount? {
        let controller = try configuredController()
        // #TODO - Networked Identity: localize once the final mobile copy is approved.
        let content = LinkController.AuthenticationContent(
            title: "Continue with Link",
            subtitle: mode == .save
                ? "Sign in or create an account to get started."
                : "Sign in to use a saved ID.",
            consentAction: .entered_phone_number_email_clicked_save_with_link_identity
        )
        let result: LinkController.AuthenticationResult = try await withCheckedThrowingContinuation { continuation in
            controller.presentForAuthentication(email: email, content: content, from: viewController) {
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
        let credentials: NetworkedIdentityConsumerCredentials? = {
            guard let secret = account.consumerSessionClientSecret, !secret.isEmpty,
                  let publishableKey = account.consumerPublishableKey, !publishableKey.isEmpty
            else {
                return nil
            }
            return NetworkedIdentityConsumerCredentials(publishableKey: publishableKey, sessionClientSecret: secret)
        }()
        return NetworkedIdentityLinkAccount(
            email: account.email,
            redactedPhoneNumber: account.redactedPhoneNumber ?? "",
            isVerified: account.sessionState == .verified,
            credentials: credentials
        )
    }
}
