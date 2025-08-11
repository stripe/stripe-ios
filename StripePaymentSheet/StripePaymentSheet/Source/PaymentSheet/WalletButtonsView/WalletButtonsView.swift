//
//  WalletButtonsView.swift
//  StripePaymentSheet
//

import PassKit
import SwiftUI
import WebKit

@available(iOS 16.0, *)
@_spi(STP) public struct WalletButtonsView: View {
    enum ExpressType: Hashable {
        case applePay
        case link
        case linkInlineVerification(PaymentSheetLinkAccount)
        case shopPay
    }

    let flowController: PaymentSheet.FlowController
    let confirmHandler: (PaymentSheetResult) -> Void
    @State var orderedWallets: [ExpressType]

    @_spi(STP) public init(flowController: PaymentSheet.FlowController,
                           confirmHandler: @escaping (PaymentSheetResult) -> Void) {
        self.confirmHandler = confirmHandler
        self.flowController = flowController

        let wallets = WalletButtonsView.determineAvailableWallets(for: flowController)
        self._orderedWallets = State(initialValue: wallets)
    }

    init(flowController: PaymentSheet.FlowController,
         confirmHandler: @escaping (PaymentSheetResult) -> Void,
         orderedWallets: [ExpressType]) {
        self.flowController = flowController
        self.confirmHandler = confirmHandler
        self._orderedWallets = State(initialValue: orderedWallets)
    }

    @_spi(STP) public var body: some View {
        if !orderedWallets.isEmpty {
            VStack(spacing: 8) {
                ForEach(orderedWallets, id: \.self) { wallet in
                    let completion: () -> Void = {
                        Task {
                            checkoutTapped(wallet)
                        }
                    }

                    switch wallet {
                    case .applePay:
                        ApplePayButton(
                            height: flowController.configuration.appearance.primaryButton.height,
                            cornerRadius: flowController.configuration.appearance.primaryButton.cornerRadius ?? flowController.configuration.appearance.cornerRadius,
                            action: completion
                        )
                    case .link:
                        LinkButton(
                            height: flowController.configuration.appearance.primaryButton.height,
                            cornerRadius: flowController.configuration.appearance.primaryButton.cornerRadius ?? flowController.configuration.appearance.cornerRadius,
                            action: completion
                        )
                    case .linkInlineVerification(let account):
                        LinkInlineVerificationView(
                            account: account,
                            appearance: flowController.configuration.appearance,
                            onComplete: completion
                        )
                    case .shopPay:
                        ShopPayButton(
                            height: flowController.configuration.appearance.primaryButton.height,
                            cornerRadius: flowController.configuration.appearance.primaryButton.cornerRadius ?? flowController.configuration.appearance.cornerRadius
                        ) {
                            Task {
                                checkoutTapped(.shopPay)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .animation(.easeInOut, value: orderedWallets)
            .onAppear {
                flowController.walletButtonsShownExternally = true
            }
            .onDisappear {
                flowController.walletButtonsShownExternally = false
            }
        }
    }

    private static func determineAvailableWallets(for flowController: PaymentSheet.FlowController) -> [ExpressType] {
        // Determine available wallets and their order from elementsSession
        var wallets: [ExpressType] = []

        // Always show Link at the top if it's enabled, regardless of orderedPaymentMethodTypesAndWallets
        if PaymentSheet.isLinkEnabled(
            elementsSession: flowController.elementsSession,
            configuration: flowController.configuration
        ) {
            let canUseLinkInlineVerification: Bool = {
                let featureFlagEnabled = PaymentSheet.LinkFeatureFlags.enableLinkInlineVerification
                let canUseNativeLink = deviceCanUseNativeLink(
                    elementsSession: flowController.elementsSession,
                    configuration: flowController.configuration
                )
                return featureFlagEnabled && canUseNativeLink
            }()

            if canUseLinkInlineVerification,
               let linkAccount = LinkAccountContext.shared.account,
               linkAccount.sessionState == .requiresVerification {
                wallets.append(.linkInlineVerification(linkAccount))
            } else {
                wallets.append(.link)
            }
        }

        // Add other wallets based on their order in orderedPaymentMethodTypesAndWallets
        for type in flowController.elementsSession.orderedPaymentMethodTypesAndWallets {
            switch type {
            case "link":
                // Skip Link here since we already added it at the top if enabled
                continue
            case "apple_pay":
                if PaymentSheet.isApplePayEnabled(elementsSession: flowController.elementsSession, configuration: flowController.configuration) {
                    wallets.append(.applePay)
                }
            case "shop_pay":
                wallets.append(.shopPay)
            default:
                continue
            }
        }
        return wallets
    }

    func checkoutTapped(_ expressType: ExpressType) {
        switch expressType {
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
        case .link, .linkInlineVerification:
            let linkController = PayWithNativeLinkController(
                mode: .paymentMethodSelection,
                intent: flowController.intent,
                elementsSession: flowController.elementsSession,
                configuration: flowController.configuration,
                analyticsHelper: flowController.analyticsHelper
            )
            linkController.presentForPaymentMethodSelection(
                from: WindowAuthenticationContext().authenticationPresentingViewController(),
                initiallySelectedPaymentDetailsID: nil,
                shouldShowSecondaryCta: false,
                canSkipWalletAfterVerification: flowController.elementsSession.canSkipLinkWallet,
                completion: { confirmOptions, _ in
                    guard let confirmOptions else {
                        self.orderedWallets = WalletButtonsView.determineAvailableWallets(for: flowController)
                        return
                    }
                    flowController.viewController.linkConfirmOption = confirmOptions
                    flowController.updatePaymentOption()
                }
            )
        case .shopPay:
            guard let shopPayConfig = flowController.configuration.shopPay else {
                // Shop Pay configuration is required
                let error = PaymentSheetError.integrationError(nonPIIDebugDescription: "Shop Pay configuration is missing")
                confirmHandler(.failed(error: error))
                return
            }

            // Present Shop Pay via ECE WebView
            let shopPayPresenter = ShopPayECEPresenter(
                flowController: flowController,
                configuration: shopPayConfig,
                analyticsHelper: flowController.analyticsHelper
            )
            shopPayPresenter.present(from: WindowAuthenticationContext().authenticationPresentingViewController(),
                                     confirmHandler: confirmHandler)
        }
    }

    private struct ApplePayButton: View {
        private enum Constants {
            static let defaultButtonHeight: CGFloat = 44
        }

        let height: CGFloat
        let cornerRadius: CGFloat
        let action: () -> Void

        init(height: CGFloat = Constants.defaultButtonHeight, cornerRadius: CGFloat = Constants.defaultButtonHeight / 2, action: @escaping () -> Void) {
            self.height = height
            self.cornerRadius = cornerRadius
            self.action = action
        }

        var body: some View {
            PayWithApplePayButton(.plain, action: action)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .cornerRadius(cornerRadius)
        }
    }
}

class WindowAuthenticationContext: NSObject, STPAuthenticationContext {
    public func authenticationPresentingViewController() -> UIViewController {
        UIWindow.visibleViewController ?? UIViewController()
    }
}

extension PaymentSheetLinkAccount: Hashable {
    @_spi(STP) public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

#if DEBUG
@available(iOS 16.0, *)
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
        let psConfig = PaymentSheet.Configuration()
        let elementsSession = STPElementsSession(allResponseFields: [:], sessionID: "", orderedPaymentMethodTypes: [], orderedPaymentMethodTypesAndWallets: ["card", "link", "apple_pay"], unactivatedPaymentMethodTypes: [], countryCode: nil, merchantCountryCode: nil, merchantLogoUrl: nil, linkSettings: nil, experimentsData: nil, flags: [:], paymentMethodSpecs: nil, cardBrandChoice: nil, isApplePayEnabled: true, externalPaymentMethods: [], customPaymentMethods: [], passiveCaptcha: nil, customer: nil)
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 10, currency: "USD", setupFutureUsage: nil, captureMethod: .automatic, paymentMethodOptions: nil)) { _, _, _ in }
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let loadResult = PaymentSheetLoader.LoadResult(intent: intent, elementsSession: elementsSession, savedPaymentMethods: [], paymentMethodTypes: [])
        let analyticsHelper = PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: psConfig)
        return PaymentSheet.FlowController(configuration: psConfig, loadResult: loadResult, analyticsHelper: analyticsHelper)
    }
}
#endif
