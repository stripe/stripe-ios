//
//  ExpressCheckoutElementView.swift
//  StripePaymentSheet
//

import SwiftUI

/// A SwiftUI view that displays Express Checkout Element wallet buttons.
/// Obtain an instance via `ExpressCheckoutElement.view`.
@_spi(STP)
@available(iOS 16.0, *)
public struct ExpressCheckoutElementView: View {

    let element: ExpressCheckoutElement

    @_spi(STP) public var body: some View {
        WalletButtonsView(
            appearance: element.configuration.appearance,
            orderedWallets: element.availableWallets,
            linkBrandProvider: { account in
                element.configuration.resolvedLinkBrand(
                    elementsSession: element.elementsSession,
                    linkAccount: account
                )
            },
            tapHandler: { wallet in
                element.walletTapped(wallet)
            }
        )
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
