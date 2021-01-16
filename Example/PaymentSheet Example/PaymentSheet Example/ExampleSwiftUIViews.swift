//
//  ExampleAdditions.swift
//  PaymentSheet Example
//
//  Created by David Estes on 1/15/21.
//  Copyright © 2021 stripe-ios. All rights reserved.
//

import Stripe
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
  }
}

struct LoadingView: View {
  var body: some View {
    if #available(iOS 14.0, *) {
      ProgressView()
    } else {
      Text("Preparing payment…")
    }
  }
}

struct PaymentStatusView: View {
  let result: PaymentResult

  var body: some View {
    HStack {
      switch result {
      case .completed(let pi):
        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
        Text("Payment complete: (\(pi.stripeId))")
      case .failed(let error, _):
        Image(systemName: "xmark.octagon.fill").foregroundColor(.red)
        Text("Payment failed: \(error.localizedDescription)")
      case .canceled(_):
        Image(systemName: "xmark.octagon.fill").foregroundColor(.orange)
        Text("Payment canceled.")
      }
    }
  }
}

struct PaymentOptionView: View {
  let paymentOptionDisplayData: PaymentSheet.FlowController.PaymentOptionDisplayData?

  var body: some View {
    HStack {
      Image(uiImage: paymentOptionDisplayData?.image ?? UIImage(systemName: "creditcard")!)
        .resizable()
        .scaledToFit()
        .frame(maxWidth: 30, maxHeight: 30, alignment: .leading)
        .foregroundColor(.black)
      Text(paymentOptionDisplayData?.label ?? "Select a payment method")
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
      PaymentOptionView(paymentOptionDisplayData: nil)
      ExamplePaymentButtonView()
      PaymentStatusView(result: .canceled(paymentIntent: nil))
      LoadingView()
    }
  }
}
