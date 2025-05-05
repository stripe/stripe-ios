//
//  RefillView.swift
//  FruitStore
//

import Foundation
import StoreKit
import SwiftUI

@available(iOS 14.0, *)
struct RefillView: View {
    @EnvironmentObject var model: FruitModel

    var body: some View {
        // Check if payments are blocked by Parental Controls on this device.
        if SKPaymentQueue.canMakePayments() {
            Button {
                model.openRefillPage()
            } label: {
                FruitStorePaymentButtonView(text: "Buy 100 coins 💰")
                    .padding()
            }.onOpenURL { url in
                model.didCompleteRefill(url: url)
            }
        } else {
            Text("Payments are disabled on this device.")
        }
    }
}
