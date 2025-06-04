//
//  WalletButtonsView.swift
//  StripePaymentSheet
//

import PassKit
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import SwiftUI
import UIKit

@available(iOS 17.0, *)
@_spi(STP) public struct WalletButtonsView: View {
    enum ExpressType {
        case link
        case applePay
    }

    let flowController: PaymentSheet.FlowController
    let confirmHandler: (PaymentSheetResult) -> Void
    let orderedWallets: [ExpressType]

    @State private var viewModel: WalletViewModel

    @_spi(STP) public init(flowController: PaymentSheet.FlowController,
                           confirmHandler: @escaping (PaymentSheetResult) -> Void) {
        self.confirmHandler = confirmHandler
        self.flowController = flowController

        // Determine available wallets and their order from elementsSession
        var wallets: [ExpressType] = []
        for type in flowController.elementsSession.orderedPaymentMethodTypesAndWallets {
            switch type {
            case "link":
                // Also check PaymentSheet local availability logic
                if PaymentSheet.isLinkEnabled(elementsSession: flowController.elementsSession, configuration: flowController.configuration) {
                    wallets.append(.link)
                }
            case "apple_pay":
                if PaymentSheet.isApplePayEnabled(elementsSession: flowController.elementsSession, configuration: flowController.configuration) {
                    wallets.append(.applePay)
                }
            default:
                continue
            }
        }
        self.orderedWallets = wallets
        self.viewModel = WalletViewModel(from: flowController)
    }

    init(flowController: PaymentSheet.FlowController,
         confirmHandler: @escaping (PaymentSheetResult) -> Void,
         orderedWallets: [ExpressType]) {
        self.flowController = flowController
        self.confirmHandler = confirmHandler
        self.orderedWallets = orderedWallets
        self.viewModel = WalletViewModel(from: flowController)
    }

    @_spi(STP) public var body: some View {
        if !orderedWallets.isEmpty {
            VStack(spacing: 8) {
                ForEach(orderedWallets, id: \.self) { wallet in
                    switch wallet {
                    case .applePay:
                        ApplePayButton {
                            Task {
                                checkoutTapped(.applePay)
                            }
                        }
                    case .link:
                        LinkExpressCheckout(
                            mode: $viewModel.linkButtonMode,
                            session: $viewModel.session,
                            textFieldController: $viewModel.textFieldController,
                            verificationAction: { code in
                                Task {
                                    await confirmVerificationCode(code)
                                }
                            },
                            resendCodeAction: {
                                Task {
                                    await sendOTP()
                                }
                            },
                            checkoutAction: {
                                Task {
                                    if viewModel.session != nil {
                                        viewModel.linkButtonMode = .inlineVerification
                                    } else {
                                        checkoutTapped(.link)
                                    }
                                }
                            }
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .onAppear {
                flowController.walletButtonsShownExternally = true
                Task {
                    await lookupConsumer()
                }
            }
            .onDisappear {
                flowController.walletButtonsShownExternally = false
            }
        }
    }

    private func lookupConsumer() async {
        guard let email = viewModel.email else { return }

        // Ignore any lookups that fail or don't find an existing Link consumer.
        guard let session = try? await viewModel.lookup(email: email) else { return }
        viewModel.session = session.consumerSession
        viewModel.consumerPublishableKey = session.publishableKey

        // Send an OTP and switch to the inline verification mode.
        await sendOTP()
        viewModel.linkButtonMode = .inlineVerification
    }

    private func sendOTP() async {
        guard let session = try? await viewModel.startVerification() else { return }
        viewModel.session = session
    }

    private func confirmVerificationCode(_ code: String) async {
        if code != "000000" {
            viewModel.textFieldController.performInvalidCodeAnimation()
            return
        }

        do {
            let session = try await viewModel.confirmVerification(code: code)
            viewModel.session = session

            guard let email = viewModel.email else {
                throw WalletViewModel.ViewModelError.consumerNotFound
            }

            // Create the Link account object, and set it on the context.
            let linkAccount = PaymentSheetLinkAccount(
                email: email,
                session: viewModel.session,
                publishableKey: viewModel.consumerPublishableKey,
                useMobileEndpoints: viewModel.useMobileEndpoints
            )
            LinkAccountContext.shared.account = linkAccount
            checkoutTapped(.link)

            viewModel.linkButtonMode = .button
        } catch {
            viewModel.textFieldController.performInvalidCodeAnimation()
        }
    }

    func checkoutTapped(_ expressType: ExpressType) {
        switch expressType {
        case .link:
            PaymentSheet.confirm(
                configuration: flowController.configuration,
                authenticationContext: WindowAuthenticationContext(),
                intent: flowController.intent,
                elementsSession: flowController.elementsSession,
                paymentOption: .link(option: .wallet),
                paymentHandler: flowController.paymentHandler,
                analyticsHelper: flowController.analyticsHelper
            ) { result, _ in
                confirmHandler(result)
            }
        case .applePay:
            // Launch directly into Apple Pay and confirm the payment
            PaymentSheet.confirm(
                configuration: flowController.configuration,
                authenticationContext: WindowAuthenticationContext(),
                intent: flowController.intent,
                elementsSession: flowController.elementsSession,
                paymentOption: .applePay,
                paymentHandler: flowController.paymentHandler,
                analyticsHelper: flowController.analyticsHelper
            ) { result, _ in
                confirmHandler(result)
            }
        }
    }

    private struct ApplePayButton: View {
        let action: () -> Void

        var body: some View {
            PayWithApplePayButton(.plain, action: action)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .cornerRadius(100)
        }
    }

    private struct LinkButton: View {
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack(spacing: 4) {
                SwiftUI.Image(uiImage: Image.link_logo_bw.makeImage(template: false))
                        .resizable()
                        .scaledToFit()
                        .frame(height: 18)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(uiColor: .linkIconBrand))
                .foregroundColor(.black)
                .cornerRadius(100)
            }
        }
    }
}

private class WindowAuthenticationContext: NSObject, STPAuthenticationContext {
    public func authenticationPresentingViewController() -> UIViewController {
        UIWindow.visibleViewController ?? UIViewController()
    }
}

#if DEBUG
@available(iOS 17.0, *)
struct WalletButtonsView_Previews: PreviewProvider {
    static var previews: some View {
        WalletButtonsView(
            flowController: PaymentSheet.FlowController._mockFlowController(),
            confirmHandler: { _ in },
            orderedWallets: [.applePay, .link]
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}

fileprivate extension PaymentSheet.FlowController {
    static func _mockFlowController() -> PaymentSheet.FlowController {
        var psConfig = PaymentSheet.Configuration()
        psConfig.defaultBillingDetails.email = "mats@stripe.com"
        let elementsSession = STPElementsSession(allResponseFields: [:], sessionID: "", orderedPaymentMethodTypes: [], orderedPaymentMethodTypesAndWallets: ["card", "link", "apple_pay"], unactivatedPaymentMethodTypes: [], countryCode: nil, merchantCountryCode: nil, linkSettings: nil, experimentsData: nil, flags: [:], paymentMethodSpecs: nil, cardBrandChoice: nil, isApplePayEnabled: true, externalPaymentMethods: [], customPaymentMethods: [], customer: nil)
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 10, currency: "USD", setupFutureUsage: nil, captureMethod: .automatic, paymentMethodOptions: nil)) { _, _, _ in }
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let loadResult = PaymentSheetLoader.LoadResult(intent: intent, elementsSession: elementsSession, savedPaymentMethods: [], paymentMethodTypes: [])
        let analyticsHelper = PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: psConfig)
        return PaymentSheet.FlowController(configuration: psConfig, loadResult: loadResult, analyticsHelper: analyticsHelper)
    }
}
#endif
