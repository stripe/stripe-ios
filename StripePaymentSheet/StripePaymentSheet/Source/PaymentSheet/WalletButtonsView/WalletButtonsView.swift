//
//  WalletButtonsView.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeCore
import PassKit
import SwiftUI

typealias ExpressType = PaymentSheet.WalletButtonsVisibility.ExpressType

@available(iOS 16.0, *)
@_spi(STP) public struct WalletButtonsView: View {
    /// Handler called when a wallet button is tapped. Return `true` to proceed with checkout, `false` to cancel.
    /// The parameter is the wallet type as a string: "apple_pay" or "link"
    @_spi(STP) public typealias WalletButtonClickHandler = (String) -> Bool

    let appearance: PaymentSheet.Appearance
    let linkBrandProvider: (PaymentSheetLinkAccount?) -> LinkBrand
    let tapHandler: (ExpressType) -> Void
    let onAppear: (([String]) -> Void)?
    let onDisappear: (() -> Void)?
    @State var orderedWallets: [ExpressType]
    @StateObject private var linkButtonViewModel = LinkButtonViewModel()

    // MARK: - FlowController initializer

    @_spi(STP) public init(
        flowController: PaymentSheet.FlowController,
        confirmHandler: @escaping (PaymentSheetResult) -> Void,
        clickHandler: WalletButtonClickHandler? = nil
    ) {
        let wallets = WalletButtonsView.determineAvailableWallets(for: flowController)
        self._orderedWallets = State(initialValue: wallets)
        self.appearance = flowController.configuration.appearance
        self.linkBrandProvider = { account in
            flowController.configuration.resolvedLinkBrand(
                elementsSession: flowController.elementsSession,
                linkAccount: account
            )
        }
        self.onAppear = { wallets in
            flowController.walletButtonsViewState = .visible(allowedWallets: wallets)
        }
        self.onDisappear = {
            flowController.walletButtonsViewState = .hidden
        }
        self.tapHandler = { expressType in
            flowController.analyticsHelper.logWalletButtonTapped(walletType: expressType)

            if let clickHandler = clickHandler {
                guard clickHandler(expressType.rawValue) else { return }
            }

            switch expressType {
            case .applePay:
                PaymentSheet.confirm(
                    configuration: flowController.configuration,
                    authenticationContext: WindowAuthenticationContext(),
                    intent: flowController.intent,
                    elementsSession: flowController.elementsSession,
                    paymentOption: .applePay,
                    paymentHandler: flowController.paymentHandler,
                    analyticsHelper: flowController.analyticsHelper
                ) { result, _ in
                    if case .completed = result {
                        CustomerPaymentOption.setDefaultPaymentMethod(
                            .applePay,
                            forCustomer: flowController.configuration.customer?.id
                        )
                    }
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
                    completion: { confirmOptions, _ in
                        guard let confirmOptions else { return }
                        flowController.viewController.linkConfirmOption = confirmOptions
                        flowController.updatePaymentOption()
                    }
                )
            }
        }
    }

    // MARK: - Generic initializer (used by ExpressCheckoutElement)

    init(
        appearance: PaymentSheet.Appearance,
        orderedWallets: [ExpressType],
        linkBrandProvider: @escaping (PaymentSheetLinkAccount?) -> LinkBrand,
        tapHandler: @escaping (ExpressType) -> Void
    ) {
        self.appearance = appearance
        self._orderedWallets = State(initialValue: orderedWallets)
        self.linkBrandProvider = linkBrandProvider
        self.tapHandler = tapHandler
        self.onAppear = nil
        self.onDisappear = nil
    }

    // TODO: Deprecate?
    init(
        flowController: PaymentSheet.FlowController,
        confirmHandler: @escaping (PaymentSheetResult) -> Void,
        orderedWallets: [ExpressType],
        clickHandler: WalletButtonClickHandler? = nil
    ) {
        self.init(flowController: flowController, confirmHandler: confirmHandler, clickHandler: clickHandler)
        self._orderedWallets = State(initialValue: orderedWallets)
    }

    // MARK: - Body

    @_spi(STP) public var body: some View {
        if !orderedWallets.isEmpty {
            VStack(spacing: 8) {
                ForEach(orderedWallets, id: \.self) { wallet in
                    let completion: () -> Void = { tapHandler(wallet) }

                    switch wallet {
                    case .applePay:
                        ApplePayButton(
                            height: appearance.primaryButton.height,
                            // TODO (iOS 26): Respect cornerRadius = nil
                            cornerRadius: appearance.primaryButton.cornerRadius
                                ?? appearance.cornerRadius
                                ?? PaymentSheet.Appearance.defaultCornerRadius,
                            action: completion
                        )
                    case .link:
                        LinkButton(
                            height: appearance.primaryButton.height,
                            // TODO (iOS 26): Respect cornerRadius = nil
                            cornerRadius: appearance.primaryButton.cornerRadius
                                ?? appearance.cornerRadius
                                ?? PaymentSheet.Appearance.defaultCornerRadius,
                            brand: linkBrandProvider(linkButtonViewModel.account),
                            borderColor: appearance.colors.componentBorder,
                            action: completion
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .animation(.easeInOut, value: orderedWallets)
            .onAppear {
                onAppear?(orderedWallets.map(\.rawValue))
            }
            .onDisappear {
                onDisappear?()
            }
        }
    }

    // MARK: - Wallet determination (FlowController-specific)

    private static func determineAvailableWallets(
        for flowController: PaymentSheet.FlowController
    ) -> [ExpressType] {
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
            default:
                continue
            }
        }

        if flowController.elementsSession.linkPassthroughModeEnabled &&
            PaymentSheet.isLinkEnabled(elementsSession: flowController.elementsSession, configuration: flowController.configuration) {
            appendIfAllowed(.link)
        }

        return wallets
    }

    // MARK: - Internal tap entry point (used by tests)

    func checkoutTapped(_ expressType: ExpressType) {
        tapHandler(expressType)
    }

    // MARK: - Apple Pay button subview

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
        let analyticsHelper = PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: psConfig)
        let paymentMethodMessagingPromotionsHelper = PaymentMethodMessagingPromotionsHelper(elementsSession: elementsSession, intent: intent, configuration: psConfig, paymentMethodTypes: [], analyticsHelper: analyticsHelper)
        let loadResult = PaymentSheetLoader.LoadResult(intent: intent, elementsSession: elementsSession, savedPaymentMethods: [], paymentMethodTypes: [], paymentMethodMessagingPromotionsHelper: paymentMethodMessagingPromotionsHelper, paymentMethodOrientation: .vertical)
        return PaymentSheet.FlowController(configuration: psConfig, loadResult: loadResult, analyticsHelper: analyticsHelper)
    }
}
#endif
