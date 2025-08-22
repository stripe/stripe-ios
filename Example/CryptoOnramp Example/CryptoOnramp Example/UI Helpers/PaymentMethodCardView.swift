//
//  PaymentMethodCardView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/11/25.
//

import SwiftUI

@_spi(CryptoOnrampSDKPreview)
import StripeCryptoOnramp

/// A view that displays the information from `PaymentMethodSelectionResult.PaymentMethodDisplayData`
struct PaymentMethodCardView: View {

    /// The `PaymentMethodDisplayData` containing the details to render.
    let preview: PaymentMethodDisplayData

    // MARK: - View

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top, spacing: 12) {
                Image(uiImage: preview.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .padding(8)
                    .background(.white.opacity(0.3))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Text(preview.label)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()
            }

            Spacer()

            if let sublabel = preview.sublabel, !sublabel.isEmpty {
                Text(sublabel)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .aspectRatio(1.6 / 1, contentMode: .fit)
        .frame(maxHeight: 180)
        .padding()
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    PaymentMethodCardView(preview: .init(icon: UIImage(systemName: "wallet.bifold")!, label: "Crypto Onramp Example", sublabel: "Visa Credit •••• 4242"))

    PaymentMethodCardView(preview: .init(icon: UIImage(systemName: "wallet.bifold")!, label: "Crypto Onramp Example", sublabel: nil))
}
