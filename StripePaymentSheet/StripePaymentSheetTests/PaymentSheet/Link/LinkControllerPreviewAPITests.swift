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

        let result: LinkController.PaymentMethodResult = .canceled
        _ = result

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
        }
    }
}
