//
//  LinkControllerPreviewAPITests.swift
//  StripePaymentSheetTests

import UIKit
@testable @_spi(LinkControllerPreview) import StripePaymentSheet
import XCTest

final class LinkControllerPreviewAPITests: XCTestCase {
    @MainActor
    func testPreviewSPISurfaceCompiles() {
        _ = LinkPaymentMethodType.card

        let result: LinkController.PaymentMethodResult = .canceled
        _ = result

        if false {
            LinkController.create(mode: .payment) { result in
                _ = result
            }

            Task { @MainActor in
                let controller = try await LinkController.create(mode: .payment)
                _ = controller.paymentMethodPreview

                controller.present(
                    email: "jenny.rosen@example.com",
                    phoneNumber: "+14155551234",
                    supportedPaymentMethodTypes: [.card],
                    from: UIViewController()
                ) { result in
                    _ = result
                }

                _ = try await controller.present(
                    email: "jenny.rosen@example.com",
                    phoneNumber: "+14155551234",
                    supportedPaymentMethodTypes: [.card],
                    from: UIViewController()
                )
            }
        }
    }
}
