//
//  PaymentSheet+ShopPay.swift
//  StripePaymentSheet
//
//  Created by John Woo on 6/6/25.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
import UIKit
import WebKit

extension PaymentSheet {
    static func handleShopPay(configuration: PaymentElementConfiguration,
                              authorizationContext: STPAuthenticationContext,
                              completion: @escaping (PaymentSheetResult) -> Void) {
        if #available(iOS 16.4, *) {
            Task { @MainActor in
                let shopPayWebViewController = ShopPayWebViewController(authenticationContext: authorizationContext)
                //            shopPayWebviewModel.setupWebView()
                //            shopPayWebviewModel.loadStripeCheckout()
                //            let configuredWebview = getConfiguredWebview()
                authorizationContext.authenticationPresentingViewController().present(shopPayWebViewController, animated: true)

            }
        }

    }

}
