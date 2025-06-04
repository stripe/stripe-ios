//
//  LinkExpressCheckout.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 6/4/25.
//

@_spi(STP) import StripeUICore
import SwiftUI

@available(iOS 16.0, *)
struct LinkExpressCheckout: View {
    static let buttonHeight: CGFloat = 44.0
    static let cornerRadius: CGFloat = buttonHeight / 2

    enum Mode {
        case button
        case inlineVerification
    }

    @Binding private var mode: Mode
    @Binding private var session: ConsumerSession?
    @Binding private var textFieldController: OneTimeCodeTextFieldController
    @Namespace private var headerNS

    let verificationAction: (String) -> Void
    let resendCodeAction: () -> Void
    let checkoutAction: () -> Void

    init(
        mode: Binding<Mode>,
        session: Binding<ConsumerSession?>,
        textFieldController: Binding<OneTimeCodeTextFieldController>,
        verificationAction: @escaping (String) -> Void,
        resendCodeAction: @escaping () -> Void,
        checkoutAction: @escaping () -> Void
    ) {
        self._mode = mode
        self._session = session
        self._textFieldController = textFieldController
        self.verificationAction = verificationAction
        self.resendCodeAction = resendCodeAction
        self.checkoutAction = checkoutAction
    }

    var body: some View {
        VStack(spacing: 0) {
            if mode == .button {
                ExpressCheckoutButton(action: checkoutAction)
                    .matchedGeometryEffect(id: "header", in: headerNS)
            } else if let session {
                InlineVerificationHeader(email: session.emailAddress) {
                    mode = .button
                }
                .matchedGeometryEffect(id: "header", in: headerNS)

                Divider()
                    .frame(height: 0.5)
                    .background(Color(uiColor: .linkBorderDefault))
                    .transition(.opacity)

                OneTimeCodeView(
                    session: $session,
                    textFieldController: $textFieldController,
                    onComplete: verificationAction,
                    onResend: resendCodeAction
                )
                .tint(Color(uiColor: .linkBorderSelected))
                .padding(.vertical, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: LinkExpressCheckout.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LinkExpressCheckout.cornerRadius, style: .continuous)
                .stroke(Color(uiColor: .linkBorderDefault), lineWidth: mode == .inlineVerification ? 0.5 : 0)
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.9), value: mode)
    }
}

@available(iOS 16.0, *)
private struct ExpressCheckoutButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                SwiftUI.Image(uiImage: Image.link_logo_bw.makeImage(template: false))
                    .resizable()
                    .scaledToFit()
                    .frame(height: 18)
            }
            .frame(maxWidth: .infinity)
            .frame(height: LinkExpressCheckout.buttonHeight)
            .foregroundColor(.black)
            .background(Color(uiColor: .linkIconBrand))
        }
    }
}

@available(iOS 16.0, *)
private struct InlineVerificationHeader: View {
    let email: String
    var onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            Text("Email")
                .font(.body)
                .foregroundColor(Color(uiColor: .linkTextBrand))

            Spacer(minLength: 22)

            ShimmerEffect(color: Color(uiColor: .linkTextBrand)) { gradient in
                Text(email)
                    .font(.headline)
                    .foregroundStyle(gradient)
            }

            Button(action: onDismiss) {
                SwiftUI.Image(systemName: "xmark")
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
        .frame(height: 54.0)
        .background(Color(uiColor: .linkBrandBackground))
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var linkButtonMode: LinkExpressCheckout.Mode = .button
    LinkExpressCheckout(
        mode: $linkButtonMode,
        session: .constant(nil),
        textFieldController: .constant(.init()),
        verificationAction: { _ in },
        resendCodeAction: {},
        checkoutAction: {
            linkButtonMode = .inlineVerification
        }
    )
    .padding()
}
