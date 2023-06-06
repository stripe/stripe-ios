//
//  PayWithLinkController.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 7/18/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import AuthenticationServices
import SafariServices
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

/// Standalone Link controller
final class PayWithLinkController: NSObject {
    private let paymentHandler: STPPaymentHandler

    private var continuation: CheckedContinuation<LinkPayment, Error>?

    private var selfRetainer: PayWithLinkController?

    private weak var presentingViewController: UIViewController?

    let intent: Intent
    let configuration: PaymentSheet.Configuration

    init(intent: Intent, configuration: PaymentSheet.Configuration) {
        self.intent = intent
        self.configuration = configuration
        self.paymentHandler = .init(apiClient: configuration.apiClient)
    }

    @MainActor
    func present(from presentingController: UIViewController) async throws -> LinkPayment {
        // Similarly to `PKPaymentAuthorizationController`, `PayWithLinkController` should retain
        // itself while presenting.
        presentingViewController = presentingController
        selfRetainer = self

        let payment: LinkPayment
        // TODO: construct popup URL
        let popupURL = URL(string: "https://google.com")!

        if let returnURLString = configuration.returnURL, let returnURL = URL(string: returnURLString) {
            let payWithLinkVC = SFSafariViewController(url: popupURL)
            payWithLinkVC.dismissButtonStyle = .cancel
            payWithLinkVC.delegate = self
            STPURLCallbackHandler.sharedHandler.register(self, for: returnURL)

            if UIDevice.current.userInterfaceIdiom == .pad {
                payWithLinkVC.modalPresentationStyle = .formSheet
            } else {
                payWithLinkVC.modalPresentationStyle = .overFullScreen
            }

            payment = try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                presentingController.present(payWithLinkVC, animated: true)
            }
        } else {
            payment = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<LinkPayment, Error>) in
                let payWithLinkVC = ASWebAuthenticationSession(url: popupURL, callbackURLScheme: "link-popup://", completionHandler: { [self] url, error in
                    if let error = error as? ASWebAuthenticationSessionError, error.code == ASWebAuthenticationSessionError.canceledLogin {
                        continuation.resume(throwing: LinkError.canceled)
                    } else if let error {
                        continuation.resume(throwing: error)
                    } else if let url {
                        continuation.resume(with: Result(catching: { try parseURL(url) }))
                    } else {
                        continuation.resume(throwing: LinkError.malformedURL)
                    }
                })
                payWithLinkVC.prefersEphemeralWebBrowserSession = true
                payWithLinkVC.presentationContextProvider = self
                payWithLinkVC.start()
            }
        }
        return payment
    }

    private func parseURL(_ url: URL) throws -> LinkPayment {
        // TODO: define full URL contract
        guard
            let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
            let linkStatus = query.first(where: { $0.name == "link_status" })?.value else {
            throw LinkError.noStatus
        }
        switch linkStatus {
        case "complete":
            guard let paymentMethod = query.first(where: { $0.name == "pm" })?.value else {
                throw LinkError.malformedURL
            }
            let email = query.first(where: { $0.name == "email" })?.value
            return LinkPayment(paymentMethodID: paymentMethod, email: email)
        case "logout":
            throw LinkError.logout
        default:
            throw LinkError.malformedURL
        }
    }
}

extension PayWithLinkController {
    enum LinkError: Error {
        case canceled
        case logout
        case malformedURL
        case noStatus
    }

    struct LinkPayment: Equatable {
        let paymentMethodID: String
        let email: String?
    }
}

extension PayWithLinkController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        continuation?.resume(throwing: LinkError.canceled)
    }
}

extension PayWithLinkController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return presentingViewController?.viewIfLoaded?.window ?? UIWindow()
    }
}

extension PayWithLinkController: STPURLCallbackListener {
    func handleURLCallback(_ url: URL) -> Bool {
        let continuation = self.continuation
        self.continuation = nil
        continuation?.resume(with: Result(catching: { try parseURL(url) }))
        return true
    }
}
