//
//  WalletButtonsView.swift
//  StripePaymentSheet
//

import PassKit
import StripeCore
@_spi(STP) import StripeUICore
import SwiftUI
import UIKit

@available(iOS 16.0, *)
@_spi(STP) public struct WalletButtonsView: View {
    let flowController: PaymentSheet.FlowController
    let confirmHandler: (PaymentSheetResult) -> Void
    @State private var showingApplePay: Bool
    @State private var showingLink: Bool

    init(showingApplePay: Bool = false,
         showingLink: Bool = false,
         flowController: PaymentSheet.FlowController,
         confirmHandler: @escaping (PaymentSheetResult) -> Void) {
        self.confirmHandler = confirmHandler
        self.flowController = flowController
        _showingApplePay = State(initialValue: showingApplePay)
        _showingLink = State(initialValue: showingLink)
    }

    @_spi(STP) public init(flowController: PaymentSheet.FlowController,
                           confirmHandler: @escaping (PaymentSheetResult) -> Void) {
        let isApplePayEnabled = PaymentSheet.isApplePayEnabled(elementsSession: flowController.elementsSession, configuration: flowController.configuration)
        let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: flowController.elementsSession, configuration: flowController.configuration)
        self.init(showingApplePay: isApplePayEnabled, showingLink: isLinkEnabled, flowController: flowController, confirmHandler: confirmHandler)
    }

    @_spi(STP) public var body: some View {
        if showingApplePay || showingLink {
            VStack(spacing: 8) {
                if showingApplePay {
                    ApplePayButton {
                        Task {
                            checkoutTapped(.applePay)
                        }
                    }
                }
                if showingLink {
                    LinkButton {
                        Task {
                            checkoutTapped(.link)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    enum ExpressType {
        case link
        case applePay
    }

    func checkoutTapped(_ expressType: ExpressType) {
        switch expressType {
        case .link:
            // TODO: Launch into new Link ECE flow
            break
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
                .background(Color(uiColor: .linkBrand))
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
@available(iOS 16.0, *)
struct WalletButtonsView_Previews: PreviewProvider {
    static var previews: some View {
        WalletButtonsView(
            showingApplePay: true,
            showingLink: true,
            flowController: PaymentSheet.FlowController._mockFlowController(),
            confirmHandler: { _ in
            }
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}

fileprivate extension PaymentSheet.FlowController {
    static func _mockFlowController() -> PaymentSheet.FlowController {
        let psConfig = PaymentSheet.Configuration()
        let elementsSession = STPElementsSession(allResponseFields: [:], sessionID: "", orderedPaymentMethodTypes: [], unactivatedPaymentMethodTypes: [], countryCode: nil, merchantCountryCode: nil, linkSettings: nil, experimentsData: nil, flags: [:], paymentMethodSpecs: nil, cardBrandChoice: nil, isApplePayEnabled: true, externalPaymentMethods: [], customPaymentMethods: [], customer: nil)
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 10, currency: "USD", setupFutureUsage: nil, captureMethod: .automatic, paymentMethodOptions: nil)) { _, _, _ in }
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let loadResult = PaymentSheetLoader.LoadResult(intent: intent, elementsSession: elementsSession, savedPaymentMethods: [], paymentMethodTypes: [])
        let analyticsHelper = PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: psConfig)
        return PaymentSheet.FlowController(configuration: psConfig, loadResult: loadResult, analyticsHelper: analyticsHelper)
    }
}
#endif
