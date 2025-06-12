//
//  ShopPayButton.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeUICore
import SwiftUI

@available(iOS 16.0, *)
struct ShopPayButton: View {
    private enum Constants {
        static let buttonHeight: CGFloat = 44
        static let contentHeight: CGFloat = 18
        static let cornerRadius = buttonHeight / 2
        static let backgroundColor = UIColor(hex: 0x5433EB)
    }
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SwiftUI.Image(uiImage: Image.shoppay_logo_bw.makeImage(template: false))
                .resizable()
                .scaledToFit()
                .frame(height: Constants.contentHeight)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Constants.buttonHeight)
        .background(Color(Constants.backgroundColor))
        .foregroundColor(.black)
        .cornerRadius(Constants.cornerRadius)
    }
}

@available(iOS 16.0, *)
#Preview {
    ShopPayButton {

    }
}
