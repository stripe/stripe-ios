//
//  WalletButtonsView.swift
//  StripePaymentSheet
//

import PassKit
import SwiftUI
import WebKit

typealias ExpressType = PaymentSheet.WalletButtonsVisibility.ExpressType

@available(iOS 16.0, *)
@_spi(STP) public struct WalletButtonsView: View {
    /// Handler called when a wallet button is tapped. Return `true` to proceed with checkout, `false` to cancel.
    /// The parameter is the wallet type as a string: "apple_pay", "link", or "shop_pay"
    @_spi(STP) public typealias WalletButtonClickHandler = (String) -> Bool

    let flowController: PaymentSheet.FlowController
    let confirmHandler: (PaymentSheetResult) -> Void
    let clickHandler: WalletButtonClickHandler?
    @State var orderedWallets: [ExpressType]

    @_spi(STP) public init(flowController: PaymentSheet.FlowController,
                           confirmHandler: @escaping (PaymentSheetResult) -> Void,
                           clickHandler: WalletButtonClickHandler? = nil) {
        self.confirmHandler = confirmHandler
        self.flowController = flowController
        self.clickHandler = clickHandler

        let wallets = WalletButtonsView.determineAvailableWallets(for: flowController)
        self._orderedWallets = State(initialValue: wallets)
    }

    // TODO: Deprecate?
    init(flowController: PaymentSheet.FlowController,
         confirmHandler: @escaping (PaymentSheetResult) -> Void,
         orderedWallets: [ExpressType],
         clickHandler: WalletButtonClickHandler? = nil) {
        self.flowController = flowController
        self.confirmHandler = confirmHandler
        self.clickHandler = clickHandler
        self._orderedWallets = State(initialValue: orderedWallets)
    }

    @_spi(STP) public var body: some View {
        if !orderedWallets.isEmpty {
            VStack(spacing: 8) {
                ForEach(orderedWallets, id: \.self) { wallet in
                    let completion: () -> Void = {
                        checkoutTapped(wallet)
                    }

                    switch wallet {
                    case .applePay:
                        ApplePayButton(
                            height: flowController.configuration.appearance.primaryButton.height,
                            // TODO (iOS 26): Respect cornerRadius = nil
                            cornerRadius: flowController.configuration.appearance.primaryButton.cornerRadius ?? flowController.configuration.appearance.cornerRadius ?? PaymentSheet.Appearance.defaultCornerRadius,
                            action: completion
                        )
                    case .link:
                        LinkButton(
                            height: flowController.configuration.appearance.primaryButton.height,
                            // TODO (iOS 26): Respect cornerRadius = nil
                            cornerRadius: flowController.configuration.appearance.primaryButton.cornerRadius ?? flowController.configuration.appearance.cornerRadius ?? PaymentSheet.Appearance.defaultCornerRadius,
                            borderColor: flowController.configuration.appearance.colors.componentBorder,
                            action: completion
                        )
                    case .shopPay:
                        ShopPayButton(
                            height: flowController.configuration.appearance.primaryButton.height,
                            // TODO (iOS 26): Respect cornerRadius = nil
                            cornerRadius: flowController.configuration.appearance.primaryButton.cornerRadius ?? flowController.configuration.appearance.cornerRadius ?? PaymentSheet.Appearance.defaultCornerRadius
                        ) {
                            checkoutTapped(.shopPay)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .animation(.easeInOut, value: orderedWallets)
            .onAppear {
                let allowedWallets = Set(orderedWallets)
                flowController.walletButtonsViewState = .visible(allowedWallets: allowedWallets.map(\.rawValue))
            }
            .onDisappear {
                flowController.walletButtonsViewState = .hidden
            }
        }
    }

    private static func determineAvailableWallets(
        for flowController: PaymentSheet.FlowController
    ) -> [ExpressType] {
        // Determine available wallets and their order from elementsSession
        var wallets: [ExpressType] = []

        func appendIfAllowed(_ wallet: ExpressType) {
            let visibility = flowController.configuration.walletButtonsVisibility.walletButtonsView[wallet] ?? .automatic
            if visibility != .never {
                wallets.append(wallet)
            }
        }

        for type in flowController.elementsSession.orderedPaymentMethodTypesAndWallets {
            switch type {
            case "link":
                if PaymentSheet.isLinkEnabled(elementsSession: flowController.elementsSession, configuration: flowController.configuration) {
                    appendIfAllowed(.link)
                }
            case "apple_pay":
                if PaymentSheet.isApplePayEnabled(elementsSession: flowController.elementsSession, configuration: flowController.configuration) {
                    appendIfAllowed(.applePay)
                }
            case "shop_pay":
                appendIfAllowed(.shopPay)
            default:
                continue
            }
        }

        if flowController.elementsSession.linkPassthroughModeEnabled && PaymentSheet.isLinkEnabled(elementsSession: flowController.elementsSession, configuration: flowController.configuration) {
            // Link in passthrough mode won't be in `orderedPaymentMethodTypesAndWallets`, so we append it.
            appendIfAllowed(.link)
        }

        return wallets
    }

    func checkoutTapped(_ expressType: ExpressType) {
        // Log wallet button tap analytics
        flowController.analyticsHelper.logWalletButtonTapped(walletType: expressType)

        // Invoke click handler if set, and only proceed if it returns true
        if let clickHandler = clickHandler {
            let shouldProceed = clickHandler(expressType.rawValue)
            guard shouldProceed else {
                return
            }
        }

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
        case .link:
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
        let elementsSession = STPElementsSession(allResponseFields: [:], sessionID: "", configID: "", orderedPaymentMethodTypes: [], orderedPaymentMethodTypesAndWallets: ["card", "link", "apple_pay"], unactivatedPaymentMethodTypes: [], countryCode: nil, merchantCountryCode: nil, merchantLogoUrl: nil, linkSettings: nil, experimentsData: nil, flags: [:], paymentMethodSpecs: nil, cardBrandChoice: nil, isApplePayEnabled: true, externalPaymentMethods: [], customPaymentMethods: [], passiveCaptchaData: nil, customer: nil)
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 10, currency: "USD", setupFutureUsage: nil, captureMethod: .automatic, paymentMethodOptions: nil)) { _, _ in return "" }
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let loadResult = PaymentSheetLoader.LoadResult(intent: intent, elementsSession: elementsSession, savedPaymentMethods: [], paymentMethodTypes: [])
        let analyticsHelper = PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: psConfig)
        return PaymentSheet.FlowController(configuration: psConfig, loadResult: loadResult, analyticsHelper: analyticsHelper)
    }
}
#endif
