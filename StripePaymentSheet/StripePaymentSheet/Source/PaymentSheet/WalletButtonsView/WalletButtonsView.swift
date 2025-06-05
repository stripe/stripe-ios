//
//  WalletButtonsView.swift
//  StripePaymentSheet
//

import PassKit
@_spi(STP) import StripeUICore
import SwiftUI
import UIKit

@available(iOS 16.0, *)
@_spi(STP) public struct WalletButtonsView: View {
    static let buttonHeight: CGFloat = 44.0
    static let cornerRadius: CGFloat = buttonHeight / 2.0

    let flowController: PaymentSheet.FlowController
    let confirmHandler: (PaymentSheetResult) -> Void
    let orderedWallets: [ExpressType]

    // Add state variables for Link consumer detection
    @State private var linkConsumerFound: Bool = false
    @State private var linkConsumerEmail: String?

    // Track the frame of the Link button for our animation
    @State private var linkButtonFrame: CGRect = .zero

    @_spi(STP) public init(flowController: PaymentSheet.FlowController,
                           confirmHandler: @escaping (PaymentSheetResult) -> Void) {
        // Existing initialization code...
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
    }

    init(flowController: PaymentSheet.FlowController,
         confirmHandler: @escaping (PaymentSheetResult) -> Void,
         orderedWallets: [ExpressType]) {
        self.flowController = flowController
        self.confirmHandler = confirmHandler
        self.orderedWallets = orderedWallets
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
                        if linkConsumerFound, let linkConsumerEmail {
                            // Show the email verification view with matching dimensions initially
                            EmailVerificationView(
                                email: linkConsumerEmail,
                                onDismiss: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        linkConsumerFound = false
                                    }
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: linkConsumerFound ? 16 : WalletButtonsView.cornerRadius))
                            .frame(height: linkConsumerFound ? nil : WalletButtonsView.buttonHeight)
                            .transition(.asymmetric(
                                insertion: .identity.animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.3)),
                                removal: .identity.animation(.spring(response: 0.3, dampingFraction: 0.8))
                            ))
                        } else {
                            LinkButton {
                                Task {
                                    checkoutTapped(.link)
                                }
                            }
                            // Use GeometryReader to get the frame of the Link button
                            .background(
                                GeometryReader { geometry -> Color in
                                    DispatchQueue.main.async {
                                        linkButtonFrame = geometry.frame(in: .global)
                                    }
                                    return Color.clear
                                }
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: linkConsumerFound)
            .onAppear {
                flowController.walletButtonsShownExternally = true
                Task {
                    await checkLinkConsumer()
                }
            }
            .onDisappear {
                flowController.walletButtonsShownExternally = false
            }
        }
    }

    // Simulate a Link consumer lookup
    private func checkLinkConsumer() async {
        // Simulating a network delay of 2 seconds
        try? await Task.sleep(for: .seconds(2))

        // Simulate a successful lookup
        linkConsumerEmail = "mats@stripe.com"

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.3)) {
            linkConsumerFound = true
        }
    }

    enum ExpressType {
        case link
        case applePay
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
                .frame(height: WalletButtonsView.buttonHeight)
                .cornerRadius(WalletButtonsView.cornerRadius)
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
                .frame(height: WalletButtonsView.buttonHeight)
                .background(Color(uiColor: .linkIconBrand))
                .foregroundColor(.black)
                .cornerRadius(WalletButtonsView.cornerRadius)
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
        let elementsSession = STPElementsSession(allResponseFields: [:], sessionID: "", orderedPaymentMethodTypes: [], orderedPaymentMethodTypesAndWallets: ["card", "link", "apple_pay"], unactivatedPaymentMethodTypes: [], countryCode: nil, merchantCountryCode: nil, linkSettings: nil, experimentsData: nil, flags: [:], paymentMethodSpecs: nil, cardBrandChoice: nil, isApplePayEnabled: true, externalPaymentMethods: [], customPaymentMethods: [], customer: nil)
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 10, currency: "USD", setupFutureUsage: nil, captureMethod: .automatic, paymentMethodOptions: nil)) { _, _, _ in }
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let loadResult = PaymentSheetLoader.LoadResult(intent: intent, elementsSession: elementsSession, savedPaymentMethods: [], paymentMethodTypes: [])
        let analyticsHelper = PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: psConfig)
        return PaymentSheet.FlowController(configuration: psConfig, loadResult: loadResult, analyticsHelper: analyticsHelper)
    }
}
#endif
