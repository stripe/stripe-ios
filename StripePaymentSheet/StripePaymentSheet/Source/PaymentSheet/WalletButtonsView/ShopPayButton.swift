//
//  ShopPayButton.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeUICore
import SwiftUI

@available(iOS 16.0, *)
struct ShopPayButton: View {
    private enum Constants {
        static let defaultButtonHeight: CGFloat = 44
        static let baseContentHeight: CGFloat = 18
        static let backgroundColor = UIColor(hex: 0x5433EB)
        static let minScaleFactor: CGFloat = 0.7
        static let maxScaleFactor: CGFloat = 1.5
    }

    private let height: CGFloat
    private let cornerRadius: CGFloat
    let action: () -> Void

    init(height: CGFloat = Constants.defaultButtonHeight, cornerRadius: CGFloat = Constants.defaultButtonHeight / 2, action: @escaping () -> Void) {
        self.height = height
        self.cornerRadius = cornerRadius
        self.action = action
    }

    private var scaleFactor: CGFloat {
        let factor = height / Constants.defaultButtonHeight
        return min(max(factor, Constants.minScaleFactor), Constants.maxScaleFactor)
    }

    private var scaledContentHeight: CGFloat {
        Constants.baseContentHeight * scaleFactor
    }

    var body: some View {
        Button(action: action) {
            SwiftUI.Image(uiImage: Image.shoppay_logo_bw.makeImage(template: false))
                .resizable()
                .scaledToFit()
                .frame(height: scaledContentHeight)
                .frame(minWidth: 180, maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(Color(Constants.backgroundColor))
        .foregroundColor(.black)
        .cornerRadius(cornerRadius)
    }
}

@available(iOS 16.0, *)
#Preview {
    VStack(spacing: 20) {
        // Standard height
        ShopPayButton {

        }

        // Custom height (60pt)
        ShopPayButton(height: 60, cornerRadius: 8) {

        }

        // Tall height (80pt)
        ShopPayButton(height: 80, cornerRadius: 12) {

        }
    }
    .padding()
}
