import Combine
// Integration-guide API calls with application-owned views/helpers supplied as scaffolding.
// Use the branch's actual SPI so other sample errors are not hidden by the import defect.
@_spi(InternalOnlyAPI) import StripePaymentSheet
import SwiftUI
import UIKit

@MainActor
final class GuideController: UIViewController, PaymentElementViewDelegate {
    var checkout: CheckoutController!
    let contentStackView = UIStackView()
    let totalLabel = UILabel()
    let paymentMethodButton = UIButton()
    let payButton = UIButton()
    var cancellables = Set<AnyCancellable>()

    func configure(clientSecret: String, onExpressCheckoutResult: @escaping (CheckoutController.ConfirmResult) -> Void) async throws {
        STPAPIClient.shared.publishableKey = "pk_test_placeholder"
        var configuration = CheckoutController.Configuration(clientSecret: clientSecret, returnURL: "my-app://stripe-redirect")
        configuration.defaults.email = "jenny@example.com"
        configuration.currencySelectorElement = CurrencySelectorElement.Configuration()
        var expressCheckout = ExpressCheckoutElement.Configuration(completion: onExpressCheckoutResult)
        expressCheckout.applePayConfiguration = ExpressCheckoutElement.Configuration.ApplePayConfiguration(
            merchantId: "merchant.com.example", buttonType: .buy
        )
        configuration.expressCheckoutElement = expressCheckout
        configuration.shippingAddressElement = ShippingAddressElement.Configuration()
        configuration.paymentElement = PaymentElement.Configuration()
        checkout = try await CheckoutController(configuration: configuration)
    }

    func addElements() {
        if let currencySelector = checkout.getCurrencySelectorElement() {
            currencySelector.uiView.translatesAutoresizingMaskIntoConstraints = false
            contentStackView.addArrangedSubview(currencySelector.uiView)
        }
        let expressCheckoutView = checkout.getExpressCheckoutElement().uiView
        expressCheckoutView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(expressCheckoutView)
        let paymentElementView = checkout.getPaymentElement().uiView
        paymentElementView.delegate = self
        paymentElementView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(paymentElementView)
        checkout.$session.receive(on: DispatchQueue.main).sink { [weak self] session in
            self?.totalLabel.text = "Total \(session.totals.total.amount)"
            self?.updatePayButton()
        }.store(in: &cancellables)
        checkout.$isUpdating.receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.updatePayButton()
        }.store(in: &cancellables)
        let title = checkout.session.paymentOption.map {
            [$0.label, $0.sublabel].compactMap { $0 }.joined(separator: "\n")
        } ?? "Select payment method"
        paymentMethodButton.setTitle(title, for: .normal)
        paymentMethodButton.isEnabled = !checkout.isUpdating
    }

    func updatePayButton() {
        payButton.isEnabled = !checkout.isUpdating
            && checkout.session.paymentOption != nil
            && checkout.session.shippingAddress != nil
    }

    func presentAndConfirm() async {
        await checkout.getShippingAddressElement().present(from: self)
        await checkout.getPaymentElement().present(from: self)
        let result = await checkout.confirm(from: self)
        switch result {
        case .completed(let paymentStatus): print(paymentStatus)
        case .canceled: break
        case .failed(let error): print(error.localizedDescription)
        }
    }

    func paymentElementViewDidUpdateHeight(paymentElementView: PaymentElementUIView) {
        paymentElementView.invalidateIntrinsicContentSize()
        view.layoutIfNeeded()
    }
}

struct GuideSwiftUIView: View {
    @ObservedObject var checkout: CheckoutController

    var body: some View {
        ScrollView {
            VStack {
                Text("Total \(checkout.session.totals.total.amount)")
                if let currencySelector = checkout.getCurrencySelectorElement() {
                    currencySelector.view
                }
                if !checkout.session.availableExpressCheckoutPaymentMethods.isEmpty {
                    checkout.getExpressCheckoutElement().view
                        .transition(.opacity.combined(with: .move(edge: .top)).animation(.easeInOut(duration: 0.25)))
                }
                checkout.getPaymentElement().view
                Button("Add shipping address") {
                    Task { await checkout.getShippingAddressElement().present() }
                }
                Button("Select payment method") {
                    Task { await checkout.getPaymentElement().present() }
                }.disabled(checkout.isUpdating)
                Button("Pay") {
                    Task { _ = await checkout.confirm() }
                }.disabled(checkout.isUpdating || checkout.session.paymentOption == nil || checkout.session.shippingAddress == nil)
            }
        }
    }
}
