//
//  OneTimeCodeView.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 6/3/25.
//

@_spi(STP) import StripeUICore
import SwiftUI

@available(iOS 16.0, *)
struct OneTimeCodeView: View {
    @State private var code: String = ""
    @State private var isVerifying: Bool = false

    var onResend: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Enter Verification Code")
                .font(.headline)
            Text("Enter the code sent to (•••) ••• ••23 to use your saved information.")
                .font(.body)
                .multilineTextAlignment(.center)

            OneTimeCodeTextFieldRepresentable(
                text: $code,
                configuration: OneTimeCodeTextField.Configuration(
                    numberOfDigits: 6,
                    itemSpacing: 8,
                    enableDigitGrouping: false,
                    font: .systemFont(ofSize: 24, weight: .medium),
                    itemCornerRadius: 10,
                    itemHeight: 56
                ),
                theme: .default,
                isEnabled: !isVerifying,
                onComplete: { completedCode in
                    verifyCode(completedCode)
                }
            )
            .frame(height: 60)

            Button(action: onResend) {
                Text("Resend")
                    .font(.headline)
                    .foregroundColor(Color(uiColor: .linkTextBrand))
            }
//            .padding()

            if #available(iOS 14.0, *), isVerifying {
                ProgressView()
            }
        }
        .padding()
    }

    private func verifyCode(_ code: String) {
        isVerifying = true
        // Simulate verification process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isVerifying = false
            // Handle verification result
        }
    }
}

@available(iOS 16.0, *)
#Preview {
    OneTimeCodeView(onResend: {})
}
