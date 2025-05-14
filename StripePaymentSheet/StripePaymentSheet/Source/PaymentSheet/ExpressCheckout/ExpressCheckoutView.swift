//
//  ExpressCheckoutView.swift
//  StripePaymentSheet
//

import SwiftUI
import StripeCore
@_spi(STP) import StripeUICore
import PassKit
import UIKit

@available(iOS 16.0, *)
@_spi(STP) public struct ExpressCheckoutView: View {
    let flowController: PaymentSheet.FlowController
    
    @State private var showingApplePay: Bool
    @State private var showingLink: Bool
    
    init(showingApplePay: Bool = false, showingLink: Bool = false, flowController: PaymentSheet.FlowController) {
        self.flowController = flowController
        self.showingApplePay = showingApplePay
        self.showingLink = showingLink
    }
    
    @_spi(STP) public init(flowController: PaymentSheet.FlowController) {
        let isApplePayEnabled = PaymentSheet.isApplePayEnabled(elementsSession: flowController.elementsSession, configuration: flowController.configuration)
        let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: flowController.elementsSession, configuration: flowController.configuration)
        self.init(showingApplePay: isApplePayEnabled, showingLink: isLinkEnabled, flowController: flowController)
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
        // Handle checkout action

        switch expressType {
        case .link:
            // TODO: Launch into new Link ECE flow
            break
        case .applePay:
            // Launch into Apple Pay
            PaymentSheet.confirm(
                configuration: flowController.configuration,
                authenticationContext: WindowAuthenticationContext(),
                intent: flowController.intent,
                elementsSession: flowController.elementsSession,
                paymentOption: .applePay,
                paymentHandler: flowController.paymentHandler,
                analyticsHelper: flowController.analyticsHelper
            ) { result, _ in
                // Do something with result?
            }
            break
        }
        flowController.confirm(from: UIViewController()) { _ in
            // handle result
            // probably this block should be passed in by the initializer
            
        }
    }
}

fileprivate class WindowAuthenticationContext: NSObject, STPAuthenticationContext {
    public func authenticationPresentingViewController() -> UIViewController {
        UIWindow.visibleViewController ?? UIViewController()
    }
}

@available(iOS 16.0, *)
private struct ApplePayButton: View {
    let action: () -> Void
    
    var body: some View {
        PayWithApplePayButton(.plain, action: action)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .cornerRadius(100)
    }
}

@available(iOS 16.0, *)
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

#if DEBUG
@available(iOS 16.0, *)
struct ExpressCheckoutView_Previews: PreviewProvider {
    static var previews: some View {
        ExpressCheckoutView(
            showingApplePay: true,
            showingLink: true,
            flowController: PaymentSheet.FlowController._mockFlowController()
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}

fileprivate extension PaymentSheet.FlowController {
    static func _mockFlowController() -> PaymentSheet.FlowController {
        let psConfig = PaymentSheet.Configuration()
        let elementsSession = STPElementsSession(allResponseFields: [:], sessionID: "", orderedPaymentMethodTypes: [], unactivatedPaymentMethodTypes: [], countryCode: nil, merchantCountryCode: nil, linkSettings: nil, experimentsData: nil, flags: [:], paymentMethodSpecs: nil, cardBrandChoice: nil, isApplePayEnabled: true, externalPaymentMethods: [], customPaymentMethods: [], customer: nil)
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 10, currency: "USD", setupFutureUsage: nil, captureMethod: .automatic, paymentMethodOptions: nil)) { _, _, _ in
            ///
        }
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let loadResult = PaymentSheetLoader.LoadResult(intent: intent, elementsSession: elementsSession, savedPaymentMethods: [], paymentMethodTypes: [])
        let analyticsHelper = PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: psConfig)
        return PaymentSheet.FlowController(configuration: psConfig, loadResult: loadResult, analyticsHelper: analyticsHelper)
    }
}
#endif
