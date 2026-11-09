//
//  LinkControllerPreviewAPITests.swift
//  StripePaymentSheetTests

@testable @_spi(LinkControllerPreview) import StripePaymentSheet
import UIKit
import XCTest

final class LinkControllerPreviewAPITests: XCTestCase {
    @MainActor
    func testPreviewSPISurfaceCompiles() {
        _ = LinkPaymentMethodType.card
        _ = LinkConfiguration(supportedPaymentMethodTypes: [.card])
        _ = LinkConfiguration(paymentMethodTypes: ["link"]).paymentMethodTypes
        _ = LinkConfiguration(supportedPaymentMethodTypes: [.card], allowLogout: false).allowLogout
        _ = LinkConfiguration(supportedPaymentMethodTypes: [.card], merchantDisplayName: "Example Merchant")
        _ = LinkConfiguration(supportedPaymentMethodTypes: [.card], billingDetailsCollectionConfiguration: .init())
        _ = LinkConfiguration(billingDetailsCollectionConfiguration: .init()).billingDetailsCollectionConfiguration
        _ = LinkConfiguration(financialConnectionsPermissions: ["payment_method", "balances"]).financialConnectionsPermissions
        _ = LinkConfiguration(returnURL: "example://stripe-redirect").returnURL

        let result: LinkController.PaymentMethodResult = .canceled
        _ = result

        let integrationErrors: [LinkController.IntegrationError] = [
            .noPaymentMethodSelected,
            .noActiveLinkConsumer,
            .missingAppAttestation,
            .linkUnavailable,
            .unsupportedIntentConfiguration,
            .configurationRequiresNativeLink,
        ]
        _ = integrationErrors.map(\.errorDescription)

        let intentConfiguration = PaymentSheet.IntentConfiguration(
            mode: .payment(amount: 1099, currency: "usd")
        ) { _, _ in "pi_secret_123" }

        if false {
            LinkController.create(
                configuration: .init(supportedPaymentMethodTypes: [.card], paymentMethodTypes: ["link"])
            ) { result in
                _ = result
            }

            Task { @MainActor in
                let controller = try await LinkController.create(
                    configuration: .init(supportedPaymentMethodTypes: [.card], paymentMethodTypes: ["link"])
                )
                _ = controller.paymentMethodPreview

                controller.present(
                    email: "jenny.rosen@example.com",
                    phoneNumber: "+14155551234",
                    from: UIViewController()
                ) { result in
                    _ = result
                }

                _ = try await controller.present(
                    email: "jenny.rosen@example.com",
                    phoneNumber: "+14155551234",
                    from: UIViewController()
                )

                controller.confirmSetupIntent(
                    clientSecret: "seti_secret_123",
                    from: UIViewController()
                ) { result in
                    _ = result
                }

                _ = try await controller.confirmSetupIntent(
                    clientSecret: "seti_secret_123",
                    from: UIViewController()
                )
            }

            // Confirm inside Link with an intent configuration
            LinkController.create(
                intentConfiguration: intentConfiguration,
                configuration: .init(supportedPaymentMethodTypes: [.card])
            ) { result in
                _ = result
            }

            Task { @MainActor in
                let controller = try await LinkController.create(
                    intentConfiguration: intentConfiguration,
                    configuration: .init(supportedPaymentMethodTypes: [.card])
                )
                _ = try await controller.present(
                    email: "jenny.rosen@example.com",
                    from: UIViewController()
                )
            }
        }
    }
}
