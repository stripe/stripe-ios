//
//  LinkInlineVerificationViewSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Mat Schmid on 7/23/25.
//

@_spi(STP)@testable import StripeCore
import StripeCoreTestUtils
@_spi(STP)@testable import StripePaymentSheet
import SwiftUI
import UIKit

@MainActor
class LinkInlineVerificationViewSnapshotTests: STPSnapshotTestCase {
    private let frame = CGRect(x: 0, y: 0, width: 328, height: 328)

    @available(iOS 16.0, *)
    func testLinkInlineVerificationView_NoPaymentMethodPreview() {
        verify()
    }

    @available(iOS 16.0, *)
    func testLinkInlineVerificationView_WithVisaPaymentMethodPreview() {
        verify(
            displayablePaymentDetails: ConsumerSession.DisplayablePaymentDetails(
                defaultCardBrand: "VISA",
                defaultPaymentType: .card,
                last4: "4242"
            )
        )
    }

    @available(iOS 16.0, *)
    func testLinkInlineVerificationView_WithBankPaymentMethodPreview() {
        verify(
            displayablePaymentDetails: ConsumerSession.DisplayablePaymentDetails(
                defaultCardBrand: nil,
                defaultPaymentType: .bankAccount,
                last4: "6789"
            )
        )
    }

    @available(iOS 16.0, *)
    func testLinkInlineVerificationView_StartVerificationError() {
        verify(startVerificationError: makeStartVerificationRateLimitError())
    }

    @available(iOS 16.0, *)
    private func verify(
        displayablePaymentDetails: ConsumerSession.DisplayablePaymentDetails? = nil,
        startVerificationError: Error? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let account = PaymentSheetLinkAccount._testValue(
            email: "jane.diaz@email.com",
            isRegistered: true,
            displayablePaymentDetails: displayablePaymentDetails
        )
        let viewModel = SnapshotLinkInlineVerificationViewModel(account: account, appearance: .default)
        viewModel.startVerificationError = startVerificationError

        let verificationView = LinkInlineVerificationView(
            viewModel: viewModel,
            onComplete: { }
        )
        let vc = UIHostingController(rootView: verificationView)

        // Need to host the SwiftUI view in a window for iOSSnapshotTestCase to work:
        let window = UIWindow(frame: frame)
        window.rootViewController = vc
        window.makeKeyAndVisible()

        STPSnapshotVerifyView(vc.view, identifier: nil, file: file, line: line)
    }

    private func makeStartVerificationRateLimitError() -> NSError {
        NSError.stp_error(
            errorType: "invalid_request_error",
            stripeErrorCode: LinkUtils.ConsumerErrorCode.consumerVerificationMaxAttemptsExceeded.rawValue,
            stripeErrorMessage: LinkUtils.ConsumerErrorCode.consumerVerificationMaxAttemptsExceeded.localizedDescription,
            errorParam: nil,
            declineCode: nil,
            intent: nil,
            httpResponse: HTTPURLResponse(
                url: URL(string: "https://api.stripe.com/v1/consumers/sessions/start_verification")!,
                statusCode: 429,
                httpVersion: nil,
                headerFields: nil
            )
        )
    }

    @available(iOS 16.0, *)
    func testLinkInlineVerificationView_WithGenericPaymentMethodPreview() {
        let displayJson: [String: Any] = [
            "label": "Affirm",
            "sublabel": "Affirm •••• 1234",
        ]
        let data = try! JSONSerialization.data(withJSONObject: displayJson)
        let display = try! JSONDecoder().decode(ConsumerPaymentDetails.DisplayMetadata.self, from: data)

        let displayablePaymentDetails = ConsumerSession.DisplayablePaymentDetails(
            defaultCardBrand: nil,
            defaultPaymentType: .unparsable,
            last4: nil,
            display: display
        )

        let account = PaymentSheetLinkAccount._testValue(
            email: "jane.diaz@email.com",
            isRegistered: true,
            displayablePaymentDetails: displayablePaymentDetails
        )

        let verificationView = LinkInlineVerificationView(
            account: account,
            appearance: .default,
            onComplete: { }
        )

        let vc = UIHostingController(rootView: verificationView)

        // Need to host the SwiftUI view in a window for iOSSnapshotTestCase to work:
        let window = UIWindow(frame: frame)
        window.rootViewController = vc
        window.makeKeyAndVisible()

        STPSnapshotVerifyView(vc.view, identifier: nil, file: #filePath, line: #line)
    }
}

private final class SnapshotLinkInlineVerificationViewModel: LinkInlineVerificationViewModel {
    @MainActor
    override func startVerification() async { }
}
