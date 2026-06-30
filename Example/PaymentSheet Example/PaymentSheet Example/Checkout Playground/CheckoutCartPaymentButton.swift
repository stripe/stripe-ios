//
//  CheckoutCartPaymentButton.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 3/3/26.
//

@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentSheet
import SwiftUI

struct CheckoutCartPaymentButton: View {
    @ObservedObject var checkout: Checkout
    let onDismiss: () -> Void

    private var session: Checkout.Session { checkout.session }

    @State private var flowController: PaymentSheet.FlowController?
    @State private var isLoadingFlowController = false
    @State private var loadError: Error?
    @State private var paymentResult: PaymentSheetResult?

    var body: some View {
        VStack {
            if let result = paymentResult {
                paymentResultView(result: result)
            } else if let flowController {
                CheckoutFlowControllerView(
                    flowController: flowController,
                    session: session,
                    paymentResult: $paymentResult
                )
            } else if isLoadingFlowController {
                ProgressView()
                    .padding()
            } else if let loadError {
                errorView(error: loadError)
            } else {
                Color.clear
                    .onAppear { loadFlowController() }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func paymentResultView(result: PaymentSheetResult) -> some View {
        switch result {
        case .completed:
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                Text("Payment Successful!")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                Color(UIColor.systemBackground)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
            )
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    onDismiss()
                }
            }
        case .canceled:
            Color.clear
                .onAppear { paymentResult = nil }
        case .failed(let error):
            errorView(error: error)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        paymentResult = nil
                    }
                }
        }
    }

    @ViewBuilder
    private func errorView(error: Error) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 36))
                .foregroundColor(.red)
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            Color(UIColor.systemBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
    }

    // MARK: - Helpers

    private func loadFlowController() {
        isLoadingFlowController = true
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = "payments-example://stripe-redirect"
        PaymentSheet.FlowController.create(
            checkout: checkout,
            configuration: configuration
        ) { result in
            isLoadingFlowController = false
            switch result {
            case .success(let fc):
                flowController = fc
            case .failure(let error):
                loadError = error
            }
        }
    }
}

@available(iOS 15.0, *)
private struct CheckoutFlowControllerView: View {
    @ObservedObject var flowController: PaymentSheet.FlowController
    let session: Checkout.Session
    @Binding var paymentResult: PaymentSheetResult?

    @State private var isShowingPaymentOptions = false
    @State private var isConfirming = false

    var body: some View {
        VStack(spacing: 12) {
            Button {
                isShowingPaymentOptions = true
            } label: {
                HStack {
                    if let paymentOption = flowController.paymentOption {
                        Image(uiImage: paymentOption.image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 20)
                        Text(paymentOption.label)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    } else {
                        Text("Select payment method")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
            }
            .padding(.horizontal)
            .paymentOptionsSheet(
                isPresented: $isShowingPaymentOptions,
                paymentSheetFlowController: flowController,
                onSheetDismissed: {}
            )

            Button {
                isConfirming = true
            } label: {
                HStack {
                    Text("Checkout")
                    Spacer()
                    if let total = session.total, let currency = session.currency {
                        Text(formatCartCurrency(amount: total.total.minorUnitsAmount, currency: currency))
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(flowController.paymentOption != nil ? Color.blue : Color.gray)
                .cornerRadius(14)
            }
            .disabled(flowController.paymentOption == nil)
            .padding(.horizontal)
            .paymentConfirmationSheet(
                isConfirming: $isConfirming,
                paymentSheetFlowController: flowController,
                onCompletion: { result in
                    paymentResult = result
                }
            )
        }
        .padding(.bottom, 16)
        .padding(.top, 16)
        .background(
            Color(UIColor.systemBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
    }
}
