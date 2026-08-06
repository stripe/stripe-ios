//
//  LinkInlineVerificationViewModel.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 6/4/25.
//

@_spi(STP) import StripeUICore
import SwiftUI

class LinkInlineVerificationViewModel: ObservableObject {
    let account: PaymentSheetLinkAccount
    let paymentMethodPreview: LinkPaymentMethodPreview?
    let textFieldController = OneTimeCodeTextFieldController()
    let appearance: PaymentSheet.Appearance

    @Published var code: String = ""
    @Published var loading: Bool = false
    @Published var startVerificationError: Error?

    init(account: PaymentSheetLinkAccount, appearance: PaymentSheet.Appearance) {
        self.account = account
        self.paymentMethodPreview = .init(from: account.displayablePaymentDetails)
        self.appearance = appearance
    }

    // MARK: - API Methods

    @MainActor
    func startVerification() async {
        startVerificationError = nil

        do {
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
        } catch {
            startVerificationError = error
        }
    }

    @MainActor
    func confirmVerification(code: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            account.verify(with: code, consentGranted: nil) { result in
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
