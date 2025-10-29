//
//  LinkInlineVerificationView.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 6/4/25.
//

@_spi(STP) import StripeUICore
import SwiftUI

@available(iOS 16.0, *)
struct LinkInlineVerificationView: View {
    private enum Constants {
        static let logoHeight: CGFloat = 20
        static let separatorWidth: CGFloat = 1
        static let contentSpacing: CGFloat = 8
        static let paymentMehtodIconAndNumberSpacing: CGFloat = 4
        static let fontSize: CGFloat = 14
    }

    @StateObject private var viewModel: LinkInlineVerificationViewModel
    private var onComplete: () -> Void

    init(
        account: PaymentSheetLinkAccount,
        appearance: PaymentSheet.Appearance,
        onComplete: @escaping () -> Void
    ) {
        self._viewModel = StateObject(
            wrappedValue: LinkInlineVerificationViewModel(
                account: account,
                appearance: appearance
            )
        )
        self.onComplete = onComplete
    }

    private var font: UIFont {
        UIFont.systemFont(ofSize: Constants.fontSize, weight: .medium)
            .scaled(withTextStyle: .caption1, maximumPointSize: Constants.fontSize)
    }

    var body: some View {
        VStack(spacing: LinkUI.contentSpacing) {
            HStack(spacing: Constants.contentSpacing) {
                SwiftUI.Image(uiImage: Image.link_logo.makeImage())
                    .resizable()
                    .scaledToFit()
                    .frame(height: Constants.logoHeight)

                if let paymentMethodPreview = viewModel.paymentMethodPreview {
                    Rectangle()
                        .fill(Color(uiColor: .separator))
                        .frame(width: Constants.separatorWidth, height: Constants.logoHeight)
                        .cornerRadius(Constants.separatorWidth / 2)

                    HStack(spacing: Constants.paymentMehtodIconAndNumberSpacing) {
                        SwiftUI.Image(uiImage: paymentMethodPreview.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(height: Constants.logoHeight)

                        Text(paymentMethodPreview.last4)
                            .font(Font(font))
                            .foregroundColor(Color(uiColor: .label))
                    }
                }
            }

            // TODO: Localize
            Text("Enter the code sent to \(viewModel.account.redactedPhoneNumber ?? "your phone") to use your saved information.")
                .font(Font(viewModel.appearance.asElementsTheme.fonts.subheadline.regular))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Group {
                if viewModel.loading {
                    LinkProgressIndicatorView()
                } else {
                    OneTimeCodeTextFieldRepresentable(
                        text: $viewModel.code,
                        configuration: .init(
                            enableDigitGrouping: false,
                            font: LinkUI.font(forTextStyle: .title),
                            // TODO(iOS 26): Is this supposed to apply a Liquid Glass style?
                            itemCornerRadius: viewModel.appearance.cornerRadius ?? PaymentSheet.Appearance.defaultCornerRadius,
                            itemFocusBackgroundColor: viewModel.appearance.colors.background
                        ),
                        controller: viewModel.textFieldController,
                        theme: viewModel.appearance.asElementsTheme,
                        onComplete: { code in
                            Task {
                                await onOtpComplete(code)
                            }
                        }
                    )
                    .tint(Color(uiColor: .linkBorderSelected))
                }
            }
            .frame(height: 72)

            Button(action: onResend) {
                // TODO: Localize
                Text("Resend code")
                    .font(Font(viewModel.appearance.asElementsTheme.fonts.subheadline.bold))
                    .foregroundColor(Color(uiColor: .linkTextPrimary))
            }
            .disabled(viewModel.loading)
            .opacity(viewModel.loading ? 0.5 : 1.0)
        }
        .padding(.vertical)
        .animation(.easeInOut, value: viewModel.loading)
        .onAppear {
            Task {
                try? await viewModel.startVerification()
            }
        }
    }

    private func onOtpComplete(_ code: String) async {
        viewModel.loading = true
        do {
            try await viewModel.confirmVerification(code: code)
            viewModel.loading = false
            onComplete()
        } catch {
            viewModel.textFieldController.performInvalidCodeAnimation()
            viewModel.code = ""
            viewModel.loading = false
        }
    }

    private func onResend() {
        viewModel.loading = true
        Task {
            try? await viewModel.startVerification()
            viewModel.code = ""
            viewModel.loading = false
        }
    }
}

#if DEBUG
enum Stubs {
    static let consumerSession: ConsumerSession = .init(
        clientSecret: "cs_123",
        emailAddress: "jane.diaz@gmail.com",
        redactedFormattedPhoneNumber: "(•••) ••• ••70",
        unredactedPhoneNumber: "+17070707070",
        phoneNumberCountry: "US",
        verificationSessions: [],
        supportedPaymentDetailsTypes: [.card],
        mobileFallbackWebviewParams: nil
    )

    static func displayablePaymentDetails(
        paymentMethodType: ConsumerSession.DisplayablePaymentDetails.PaymentType
    ) -> ConsumerSession.DisplayablePaymentDetails {
        .init(
            defaultCardBrand: "VISA",
            defaultPaymentType: paymentMethodType,
            last4: "4242"
        )
    }

    static func linkAccount(
        email: String = "jane.diaz@gmail.com",
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

@available(iOS 16.0, *)
#Preview {
    VStack {
        LinkInlineVerificationView(
            account: Stubs.linkAccount(paymentMethodType: nil),
            appearance: .default,
            onComplete: { }
        )
        .padding()

        LinkInlineVerificationView(
            account: Stubs.linkAccount(paymentMethodType: .card),
            appearance: .default,
            onComplete: { }
        )
        .padding()

        LinkInlineVerificationView(
            account: Stubs.linkAccount(paymentMethodType: .bankAccount),
            appearance: .default,
            onComplete: { }
        )
        .padding()
    }
}
#endif
