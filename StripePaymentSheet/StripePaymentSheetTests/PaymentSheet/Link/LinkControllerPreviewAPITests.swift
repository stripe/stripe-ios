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

        let result: LinkController.PaymentMethodResult = .canceled
        _ = result

        if false {
            LinkController.create(
                configuration: .init(supportedPaymentMethodTypes: [.card])
            ) { result in
                _ = result
            }

            Task { @MainActor in
                let controller = try await LinkController.create(
                    configuration: .init(supportedPaymentMethodTypes: [.card])
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
            }
        }
    }
}
