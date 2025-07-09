//
//  LinkAuthenticationController.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 7/9/25.
//

import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

@MainActor @_spi(STP) public class LinkAuthenticationController {
    @_spi(STP) public enum VerificationResult {
        /// Authentication was completed successfully.
        case completed
        /// Authentication was canceled by the user.
        case canceled
        /// Authentication failed due to an unrecoverable error.
        case failed(Error)
    }

    private enum AuthenticationFlow {
        case verification(PaymentSheetLinkAccount)
        case signup
    }

    @_spi(STP) public init() {}

    @_spi(STP) public func promptForLinkAuthentication(
        email: String,
        from viewController: UIViewController
    ) async throws -> VerificationResult {
        let linkAccountService = LinkAccountService(
            useMobileEndpoints: false,
            sessionID: nil
        )

        let authFlow = try await Self.lookupConsumer(
            email: email,
            linkAccountService: linkAccountService
        )

        switch authFlow {
        case .verification(let linkAccount):
            let verificationController = LinkVerificationController(linkAccount: linkAccount)

            return try await withCheckedThrowingContinuation { continuation in
                verificationController.present(from: viewController) { result in
                    switch result {
                    case .completed:
                        continuation.resume(returning: .completed)
                    case .canceled:
                        continuation.resume(returning: .canceled)
                    case .failed(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        case .signup:
            // Proceed with signup
            let signupController = LinkSignUpController(
                accountService: linkAccountService,
                linkAccount: nil,
                legalName: nil,
                country: nil
            )

            return try await withCheckedThrowingContinuation { continuation in
                signupController.present(from: viewController) { result in
                    switch result {
                    case .completed:
                        continuation.resume(returning: .completed)
                    case .canceled:
                        continuation.resume(returning: .canceled)
                    case .failed(let error):
                        continuation.resume(throwing: error)
                    case .attestationError:
                        continuation.resume(throwing: NSError(domain: "LinkAttestationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Attestation error occurred"]))
                    }
                }
            }
        }
    }

    private static func lookupConsumer(
        email: String,
        linkAccountService: LinkAccountService
    ) async throws -> AuthenticationFlow {
        try await withCheckedThrowingContinuation { continuation in
            linkAccountService.lookupAccount(
                withEmail: email,
                emailSource: .userAction,
                completion: { result in
                    switch result {
                    case .success(let linkAccount):
                        LinkAccountContext.shared.account = linkAccount

                        guard let linkAccount else {
                            continuation.resume(returning: .signup)
                            return
                        }

                        if linkAccount.isRegistered {
                            continuation.resume(returning: .verification(linkAccount))
                        } else {
                            continuation.resume(returning: .signup)
                        }
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            )
        }
    }
}
