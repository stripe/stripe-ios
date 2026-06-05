//
//  LinkButtonSnapshotTests.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 7/29/25.
//

import StripeCoreTestUtils
@_spi(STP)@testable import StripePaymentSheet
@_spi(STP)@testable import StripePaymentsTestUtils
import SwiftUI
import UIKit

@available(iOS 16.0, *)
@MainActor
class LinkButtonSnapshotTests: STPSnapshotTestCase {

    func testLinkButton_noAccount() {
        let viewModel = LinkButtonViewModel()
        viewModel.setAccount(nil)

        let linkButton = LinkButton(viewModel: viewModel, borderColor: .gray, action: {})
        let vc = UIHostingController(rootView: linkButton)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 100))
        window.rootViewController = vc
        window.makeKeyAndVisible()

        STPSnapshotVerifyView(vc.view, identifier: "no_account", file: #filePath, line: #line)
    }

    func testLinkButton_shortEmail() {
        let viewModel = LinkButtonViewModel()
        viewModel.setAccount(Stubs.linkAccount(
            email: "user@example.com",
            paymentMethodType: nil,
            isRegistered: true
        ))

        let linkButton = LinkButton(viewModel: viewModel, borderColor: .gray, action: {})
        let vc = UIHostingController(rootView: linkButton)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 100))
        window.rootViewController = vc
        window.makeKeyAndVisible()

        STPSnapshotVerifyView(vc.view, identifier: "short_email", file: #filePath, line: #line)
    }

    func testLinkButton_longEmail() {
        let viewModel = LinkButtonViewModel()
        viewModel.setAccount(Stubs.linkAccount(
            email: "this.is.a.very.long.email.address@example.com",
            paymentMethodType: nil,
            isRegistered: true
        ))

        let linkButton = LinkButton(viewModel: viewModel, borderColor: .gray, action: {})
        let vc = UIHostingController(rootView: linkButton)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 100))
        window.rootViewController = vc
        window.makeKeyAndVisible()

        STPSnapshotVerifyView(vc.view, identifier: "long_email", file: #filePath, line: #line)
    }

    func testLinkButton_cardPaymentMethodPreview() {
        let linkAccount = Stubs.linkAccount(
            email: "user@example.com",
            paymentMethodType: .card,
            isRegistered: true
        )

        let viewModel = LinkButtonViewModel()
        viewModel.setAccount(linkAccount)

        let linkButton = LinkButton(viewModel: viewModel, borderColor: .gray, action: {})
        let vc = UIHostingController(rootView: linkButton)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 100))
        window.rootViewController = vc
        window.makeKeyAndVisible()

        STPSnapshotVerifyView(vc.view, identifier: "card_payment_method", file: #filePath, line: #line)
    }

    func testLinkButton_bankPaymentMethodPreview() {
        let linkAccount = Stubs.linkAccount(
            email: "user@example.com",
            paymentMethodType: .bankAccount,
            isRegistered: true
        )

        let viewModel = LinkButtonViewModel()
        viewModel.setAccount(linkAccount)

        let linkButton = LinkButton(viewModel: viewModel, borderColor: .green, action: {})
        let vc = UIHostingController(rootView: linkButton)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 100))
        window.rootViewController = vc
        window.makeKeyAndVisible()

        STPSnapshotVerifyView(vc.view, identifier: "bank_payment_method", file: #filePath, line: #line)
    }

    func testLinkButton_genericPaymentMethodPreview() {
        let linkAccount = Stubs.linkAccount(
            email: "user@example.com",
            paymentMethodType: .unparsable,
            isRegistered: true
        )

        let viewModel = LinkButtonViewModel()
        viewModel.setAccount(linkAccount)

        let linkButton = LinkButton(viewModel: viewModel, borderColor: .gray, action: {})
        let vc = UIHostingController(rootView: linkButton)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 100))
        window.rootViewController = vc
        window.makeKeyAndVisible()

        STPSnapshotVerifyView(vc.view, identifier: "generic_payment_method", file: #filePath, line: #line)
    }
}

// MARK: - Test Stubs

#if DEBUG
enum Stubs {
    static let consumerSession: ConsumerSession = .make(
        clientSecret: "cs_123",
        emailAddress: "jane.diaz@example.com",
        redactedFormattedPhoneNumber: "(•••) ••• ••70",
        unredactedPhoneNumber: "+17070707070",
        phoneNumberCountry: "US",
        verificationSessions: [],
        supportedPaymentDetailsTypes: [ParsedEnum(.card), ParsedEnum(.bankAccount)],
        mobileFallbackWebviewParams: nil
    )

    static func displayablePaymentDetails(
        paymentMethodType: ConsumerSession.DisplayablePaymentDetails.PaymentType
    ) -> ConsumerSession.DisplayablePaymentDetails {
        switch paymentMethodType {
        case .card:
            return .init(defaultCardBrand: "VISA", defaultPaymentType: paymentMethodType, last4: "4242")
        case .bankAccount:
            return .init(defaultCardBrand: nil, defaultPaymentType: paymentMethodType, last4: "6789")
        case .unparsable:
            let displayJson: [String: Any] = [
                "label": "Affirm",
                "sublabel": "Affirm •••• 1234",
            ]
            let data = try! JSONSerialization.data(withJSONObject: displayJson)
            let display = try! JSONDecoder().decode(ConsumerPaymentDetails.DisplayMetadata.self, from: data)
            return .init(defaultCardBrand: nil, defaultPaymentType: paymentMethodType, last4: nil, display: display)
        }
    }

    static func linkAccount(
        email: String = "jane.diaz@example.com",
        paymentMethodType: ConsumerSession.DisplayablePaymentDetails.PaymentType? = nil,
        isRegistered: Bool = true
    ) -> PaymentSheetLinkAccount {
        .init(
            email: email,
            session: isRegistered ? Self.consumerSession : nil,
            publishableKey: "pk_test_123",
            displayablePaymentDetails: paymentMethodType.map { Self.displayablePaymentDetails(paymentMethodType: $0) },
            useMobileEndpoints: true,
            canSyncAttestationState: false
        )
    }
}
#endif
