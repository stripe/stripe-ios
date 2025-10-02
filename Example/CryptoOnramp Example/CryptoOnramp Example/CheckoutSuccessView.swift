//
//  CheckoutSuccessView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 9/29/25.
//

import SwiftUI

/// A final view in the flow, notifying the user that checkout succeeded.
struct CheckoutSuccessView: View {

    /// The message to display to the user beneath a "Purchase successful" label.
    let message: String

    // MARK: - View

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: 80, weight: .semibold))

            VStack(spacing: 6) {
                Text("Purchase successful")
                    .font(.title2)
                    .bold()

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            Spacer()
        }
        .offset(y: -32)
        .padding(.horizontal)
    }
}

#Preview {
    CheckoutSuccessView(message: "You’ve added 10.00 usdc to your Solana wallet.")
}
