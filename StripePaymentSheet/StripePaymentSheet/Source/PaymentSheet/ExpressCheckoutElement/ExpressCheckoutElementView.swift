//
//  ExpressCheckoutElementView.swift
//  StripePaymentSheet
//

import PassKit
import SwiftUI

/// A SwiftUI view that displays Express Checkout Element wallet buttons.
/// Obtain an instance via `ExpressCheckoutElement.view`.
@_spi(STP)
@available(iOS 16.0, *)
public struct ExpressCheckoutElementView: View {

    let element: ExpressCheckoutElement

    @StateObject private var linkButtonViewModel = LinkButtonViewModel()

    public var body: some View {
        if !element.availableWallets.isEmpty {
            VStack(spacing: 8) {
                ForEach(element.availableWallets, id: \.self) { wallet in
                    let completion: () -> Void = { element.walletTapped(wallet) }

                    switch wallet {
                    case .applePay:
                        ApplePayButtonView(
                            height: element.configuration.appearance.primaryButton.height,
                            cornerRadius: element.configuration.appearance.primaryButton.cornerRadius
                                ?? element.configuration.appearance.cornerRadius
                                ?? PaymentSheet.Appearance.defaultCornerRadius,
                            action: completion
                        )
                    case .link:
                        LinkButton(
                            height: element.configuration.appearance.primaryButton.height,
                            cornerRadius: element.configuration.appearance.primaryButton.cornerRadius
                                ?? element.configuration.appearance.cornerRadius
                                ?? PaymentSheet.Appearance.defaultCornerRadius,
                            brand: element.configuration.resolvedLinkBrand(
                                elementsSession: element.elementsSession,
                                linkAccount: linkButtonViewModel.account
                            ),
                            borderColor: element.configuration.appearance.colors.componentBorder,
                            action: completion
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .animation(.easeInOut, value: element.availableWallets)
        }
    }

    private struct ApplePayButtonView: View {
        let height: CGFloat
        let cornerRadius: CGFloat
        let action: () -> Void

        var body: some View {
            PayWithApplePayButton(.plain, action: action)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .cornerRadius(cornerRadius)
        }
    }
}

@available(iOS 16.0, *)
extension ExpressCheckoutElement {

    /// A SwiftUI view that displays the express checkout wallet buttons.
    /// Place this view in your UI where you want the wallet buttons to appear.
    /// If `hasWallets` is `false`, the view renders empty — consider hiding your container view.
    @_spi(STP) public var view: ExpressCheckoutElementView {
        return ExpressCheckoutElementView(element: self)
    }

    // MARK: - Wallet tap handling

    @MainActor
    func walletTapped(_ expressType: ExpressType) {
        analyticsHelper.logWalletButtonTapped(walletType: expressType)

        switch expressType {
        case .applePay:
            PaymentSheet.confirm(
                configuration: configuration,
                authenticationContext: WindowAuthenticationContext(),
                intent: intent,
                elementsSession: elementsSession,
                paymentOption: .applePay,
                paymentHandler: paymentHandler,
                analyticsHelper: analyticsHelper
            ) { [weak self] result, _ in
                guard let self else { return }
                if case .completed = result {
                    CustomerPaymentOption.setDefaultPaymentMethod(
                        .applePay,
                        forCustomer: configuration.customer?.id
                    )
                }
                delegate?.expressCheckoutElement(self, didCompleteWith: result)
            }

        case .link:
            let linkController = PayWithNativeLinkController(
                mode: .full,
                intent: intent,
                elementsSession: elementsSession,
                configuration: configuration,
                analyticsHelper: analyticsHelper
            )
            linkController.presentAsBottomSheet(
                from: WindowAuthenticationContext().authenticationPresentingViewController(),
                shouldOfferApplePay: false,
                shouldFinishOnClose: true,
                completion: { [weak self] result, _, _ in
                    guard let self else { return }
                    delegate?.expressCheckoutElement(self, didCompleteWith: result)
                }
            )
        }
    }
}
