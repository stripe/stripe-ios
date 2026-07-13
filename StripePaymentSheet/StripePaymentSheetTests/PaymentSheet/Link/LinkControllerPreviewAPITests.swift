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
        _ = LinkConfiguration(supportedPaymentMethodTypes: [.card], allowLogout: false).allowLogout
        _ = LinkConfiguration(supportedPaymentMethodTypes: [.card], merchantDisplayName: "Example Merchant")

        let result: LinkController.PaymentMethodResult = .canceled
        _ = result

        if false {
            LinkController.create(
                linkConfiguration: .init(supportedPaymentMethodTypes: [.card])
            ) { result in
                _ = result
            }

            LinkController.create(
                setupIntentClientSecret: "seti_secret_123"
            ) { result in
                _ = result
            }

            Task { @MainActor in
                let controller = try await LinkController.create(
                    linkConfiguration: .init(supportedPaymentMethodTypes: [.card])
                )
                _ = controller.paymentMethodPreview

                _ = try await LinkController.create(
                    setupIntentClientSecret: "seti_secret_123"
                )

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
            }
        }
    }
}
