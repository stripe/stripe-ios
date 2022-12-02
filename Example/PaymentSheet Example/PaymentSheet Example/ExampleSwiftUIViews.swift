//
//  ExampleAdditions.swift
//  PaymentSheet Example
//
//  Created by David Estes on 1/15/21.
//  Copyright © 2021 stripe-ios. All rights reserved.
//

import StripePaymentSheet
import SwiftUI

struct ExamplePaymentButtonView: View {
    var body: some View {
        HStack {
            Text("Buy").fontWeight(.bold)
        }
        .frame(minWidth: 200)
        .padding()
        .foregroundColor(.white)
        .background(Color.blue)
        .cornerRadius(6)
        .accessibility(identifier: "Buy button")
    }
}

struct ExampleLoadingView: View {
    var body: some View {
        if #available(iOS 14.0, *) {
            ProgressView()
        } else {
            Text("Preparing payment…")
        }
    }
}

struct ExamplePaymentStatusView: View {
    let result: PaymentSheetResult

    var body: some View {
        HStack {
            switch result {
            case .completed:
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                Text("Your order is confirmed!")
            case .failed(let error):
                Image(systemName: "xmark.octagon.fill").foregroundColor(.red)
                Text("Payment failed: \(error.localizedDescription)")
            case .canceled:
                Image(systemName: "xmark.octagon.fill").foregroundColor(.orange)
                Text("Payment canceled.")
            }
        }
        .accessibility(identifier: "Payment status view")
    }
}

struct ExamplePaymentOptionView: View {
    let paymentOptionDisplayData: PaymentSheet.FlowController.PaymentOptionDisplayData?

    var body: some View {
        HStack {
            Image(uiImage: paymentOptionDisplayData?.image ?? UIImage(systemName: "creditcard")!)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 30, maxHeight: 30, alignment: .leading)
                .foregroundColor(.black)
            Text(paymentOptionDisplayData?.label ?? "Select a payment method")
                // Surprisingly, setting the accessibility identifier on the HStack causes the identifier to be
                // "Payment method-Payment method". We'll set it on a single View instead.
                .accessibility(identifier: "Payment method")
        }
        .frame(minWidth: 200)
        .padding()
        .foregroundColor(.black)
        .background(Color.init(white: 0.9))
        .cornerRadius(6)
    }
}

struct ExampleSwiftUIViews_Preview: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            ExamplePaymentOptionView(paymentOptionDisplayData: nil)
            ExamplePaymentButtonView()
            ExamplePaymentStatusView(result: .canceled)
            ExampleLoadingView()
        }
    }
}
