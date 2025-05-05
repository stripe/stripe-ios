//
//  RefillView.swift
//  FruitStore
//

import Foundation
import SwiftUI
import StoreKit

struct RefillView: View {
    @EnvironmentObject var model: FruitModel

    var body: some View {
        // Check if payments are blocked by Parental Controls on this device.
        if SKPaymentQueue.canMakePayments() {
            Button {
                model.openRefillPage()
            } label: {
                ExamplePaymentButtonView(text: "Buy 100 coins 💰")
                    .padding()
            }.onOpenURL { url in
                model.didCompleteRefill(url: url)
            }
        } else {
            Text("Payments are disabled on this device.")
        }
    }
}
