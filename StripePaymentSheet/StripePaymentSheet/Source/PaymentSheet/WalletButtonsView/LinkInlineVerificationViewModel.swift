//
//  LinkInlineVerificationViewModel.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 6/4/25.
//

@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import SwiftUI

class LinkInlineVerificationViewModel: ObservableObject {
    let account: PaymentSheetLinkAccount
    let paymentMethodPreview: LinkPaymentMethodPreview?
    let textFieldController = OneTimeCodeTextFieldController()
    let appearance: PaymentSheet.Appearance

    @Published var code: String = ""
    @Published var loading: Bool = false

    init(account: PaymentSheetLinkAccount, appearance: PaymentSheet.Appearance) {
        self.account = account
        self.paymentMethodPreview = .init(from: account.displayablePaymentDetails)
        self.appearance = appearance
    }

    // MARK: - API Methods

    @MainActor
    func startVerification() async throws {
        try await withCheckedThrowingContinuation { continuation in
            account.startVerification { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    @MainActor
    func confirmVerification(code: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            account.verify(with: code) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

extension LinkInlineVerificationViewModel {
    struct LinkPaymentMethodPreview {
        let icon: UIImage
        let last4: String

        init(icon: UIImage, last4: String) {
            self.icon = icon
            self.last4 = last4
        }

        init?(from paymentDetails: ConsumerSession.DisplayablePaymentDetails?) {
            guard let paymentDetails else {
                return nil
            }

            // Required fields
            guard let last4 = paymentDetails.last4, let paymentMethodType = paymentDetails.defaultPaymentType else {
                return nil
            }

            switch paymentMethodType {
            case .card:
                guard let brand = paymentDetails.defaultCardBrand else {
                    return nil
                }
                let cardBrand = STPCard.brand(from: brand)
                let icon = STPImageLibrary.cardBrandImage(for: cardBrand)
                self.init(icon: icon, last4: last4)
            case .bankAccount:
                let icon = PaymentSheetImageLibrary.linkBankIcon()
                self.init(icon: icon, last4: last4)
            @unknown default:
                return nil
            }
        }
    }
}
