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
    let flowController: PaymentSheet.FlowController
    let confirmHandler: (PaymentSheetResult) -> Void
    @State private var showingApplePay: Bool
    @State private var showingLink: Bool

    @StateObject private var viewDelegate: WalletButtonsViewDelegate

    private var linkAccount: PaymentSheetLinkAccount? {
        LinkAccountContext.shared.account
    }

    init(showingApplePay: Bool = false,
         showingLink: Bool = false,
         flowController: PaymentSheet.FlowController,
         confirmHandler: @escaping (PaymentSheetResult) -> Void) {
        self.confirmHandler = confirmHandler
        self.flowController = flowController
        _showingApplePay = State(initialValue: showingApplePay)
        _showingLink = State(initialValue: showingLink)

        let viewDelegate = WalletButtonsViewDelegate()
        _viewDelegate = StateObject(wrappedValue: viewDelegate)
    }

    @_spi(STP) public init(flowController: PaymentSheet.FlowController,
                           confirmHandler: @escaping (PaymentSheetResult) -> Void) {
        let isApplePayEnabled = PaymentSheet.isApplePayEnabled(elementsSession: flowController.elementsSession, configuration: flowController.configuration)
        let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: flowController.elementsSession, configuration: flowController.configuration)
        self.init(showingApplePay: isApplePayEnabled, showingLink: isLinkEnabled, flowController: flowController, confirmHandler: confirmHandler)
    }

    @_spi(STP) public var body: some View {
        if let linkAccount, showingLink, !viewDelegate.dismissedLinkInlineOTP {
            let binding = Binding {
                viewDelegate.linkPaymentMethod != nil
            } set: { _ in
                // nothing
            }

            LinkInlineOTP(account: linkAccount, delegate: viewDelegate)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.linkBorderDefault), lineWidth: 1)
                )
                .cornerRadius(12)
                .alert("Login successful", isPresented: binding, actions: {}, message: {
                    Text("\(viewDelegate.linkPaymentMethod?.nickname ?? "Unknown payment method") is ready for checkout")
                })
        } else if showingApplePay || showingLink {
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

private class WalletButtonsViewDelegate: NSObject, ObservableObject, LinkVerificationViewDelegate {

    private let linkAccount: PaymentSheetLinkAccount? = LinkAccountContext.shared.account
    @Published var dismissedLinkInlineOTP: Bool = false
    @Published var linkPaymentMethod: ConsumerPaymentDetails?

    override init() {
        super.init()
        self.startVerification()
    }

    private func startVerification() {
        linkAccount?.startVerification { [weak self] result in
            switch result {
            case .success(let collectOTP):
                if collectOTP {
                    // All good
                } else {
                    // TODO: Handle this case
                }
            case .failure:
                self?.dismissedLinkInlineOTP = true
            }
        }
    }

    func verificationViewDidCancel(_ view: LinkVerificationView) {
        withAnimation {
            dismissedLinkInlineOTP = true
        }
    }

    func verificationViewResendCode(_ view: LinkVerificationView) {
        startVerification()
    }

    func verificationViewLogout(_ view: LinkVerificationView) {
        // Not expected
    }

    func verificationView(_ view: LinkVerificationView, didEnterCode code: String) {
        linkAccount?.verify(with: code) { [weak self] result in
            switch result {
            case .success:
                print("Link account verified")
                self?.fetchDefaultLinkPaymentMethod()
            case .failure(let error):
                print("Link account verification failed: \(error)")
            }
        }
    }

    private func fetchDefaultLinkPaymentMethod() {
        linkAccount?.listPaymentDetails(supportedTypes: [.card, .bankAccount]) { [weak self] result in
            switch result {
            case .success(let success):
                self?.linkPaymentMethod = success.first(where: \.isDefault) ?? success.first
            case .failure(let failure):
                print("Failed to fetch default link payment method: \(failure)")
            }
        }
    }

//    private let confirmHandler: (PaymentSheetResult) -> Void
//
//    init(confirmHandler: @escaping (PaymentSheetResult) -> Void) {
//        self.confirmHandler = confirmHandler
//        super.init()
//    }
//
//    // MARK: - PayWithLinkViewControllerDelegate
//
//    func payWithLinkViewControllerDidConfirm(
//        _ payWithLinkViewController: PayWithLinkViewController,
//        intent: Intent,
//        elementsSession: STPElementsSession,
//        with paymentOption: PaymentOption,
//        completion: @escaping (PaymentSheetResult, StripeCore.STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
//    ) {
//        payWithLinkViewController.dismiss(animated: true)
//    }
//
//    func payWithLinkViewControllerDidCancel(_ payWithLinkViewController: PayWithLinkViewController) {
//        payWithLinkViewController.dismiss(animated: true)
//    }
//
//    func payWithLinkViewControllerDidFinish(
//        _ payWithLinkViewController: PayWithLinkViewController,
//        result: PaymentSheetResult,
//        deferredIntentConfirmationType: StripeCore.STPAnalyticsClient.DeferredIntentConfirmationType?
//    ) {
//        confirmHandler(result)
//        payWithLinkViewController.dismiss(animated: true)
//    }
}

private struct LinkInlineOTP: UIViewRepresentable {

    let account: PaymentSheetLinkAccount
    let delegate: LinkVerificationViewDelegate

    func makeUIView(context: Context) -> LinkVerificationView {
        let view = LinkVerificationView(mode: .modal, linkAccount: account)
        view.delegate = delegate
        view.translatesAutoresizingMaskIntoConstraints = false

        // Set content hugging priority to ensure it doesn't expand
        view.setContentHuggingPriority(.required, for: .vertical)
        view.setContentCompressionResistancePriority(.required, for: .vertical)

        return view
    }

    func updateUIView(_ uiView: LinkVerificationView, context: Context) {
//        uiView.attributedText = text
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
