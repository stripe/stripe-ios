//
//  PaymentView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 9/17/25.
//

import SwiftUI

struct PaymentView: View {
    let onContinue: () -> Void

    @Environment(\.isLoading) private var isLoading

    var body: some View {
        ScrollView {
            VStack {
                
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .navigationTitle("Payment")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button("Continue") {
                onContinue()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading.wrappedValue)
            .opacity(isLoading.wrappedValue ? 0.5 : 1)
            .padding()
        }
    }
}

#Preview {
    PaymentView(onContinue: {})
}
