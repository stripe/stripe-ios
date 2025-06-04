//
//  OneTimeCodeView.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 6/4/25.
//

@_spi(STP) import StripeUICore
import SwiftUI

@available(iOS 16.0, *)
struct OneTimeCodeView: View {
    @State private var code: String = ""

    @Binding private var session: ConsumerSession?
    @Binding private var textFieldController: OneTimeCodeTextFieldController
    private var onComplete: (String) -> Void
    private var onResend: () -> Void

    init(
        session: Binding<ConsumerSession?>,
        textFieldController: Binding<OneTimeCodeTextFieldController>,
        onComplete: @escaping (String) -> Void,
        onResend: @escaping () -> Void
    ) {
        self._session = session
        self._textFieldController = textFieldController
        self.onComplete = onComplete
        self.onResend = onResend
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Enter Verification Code")
                .font(.headline)
            Text("Enter the code sent to \(session?.redactedFormattedPhoneNumber ?? "you") to use your saved information.")
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
                controller: textFieldController,
                theme: .default,
                onComplete: onComplete
            )
            .frame(height: 60)

            Button(action: onResend) {
                Text("Resend")
                    .font(.headline)
                    .foregroundColor(Color(uiColor: .linkTextBrand))
            }
        }
        .padding()
    }
}

@available(iOS 16.0, *)
#Preview {
    OneTimeCodeView(
        session: .constant(nil),
        textFieldController: .constant(.init()),
        onComplete: { _ in },
        onResend: {}
    )
}
