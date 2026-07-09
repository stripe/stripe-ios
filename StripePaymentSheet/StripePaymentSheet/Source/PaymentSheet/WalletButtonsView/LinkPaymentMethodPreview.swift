//
//  LinkPaymentMethodPreview.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 7/29/25.
//

@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import SwiftUI
import UIKit

struct LinkPaymentMethodPreview {
    let icon: UIImage
    let iconUrl: URL?
    let last4: String

    init(icon: UIImage, last4: String, iconUrl: URL? = nil) {
        self.icon = icon
        self.iconUrl = iconUrl
        self.last4 = last4
    }

    init?(from paymentDetails: ConsumerSession.DisplayablePaymentDetails?) {
        guard let paymentDetails else {
            return nil
        }

        // Required fields
        guard let paymentMethodType = paymentDetails.defaultPaymentType else {
            return nil
        }

        switch paymentMethodType {
        case .card:
            guard let last4 = paymentDetails.last4, let brand = paymentDetails.defaultCardBrand else {
                return nil
            }
            let cardBrand = STPCard.brand(from: brand)
            let icon = STPImageLibrary.unpaddedCardBrandImage(for: cardBrand)
            self.init(icon: icon, last4: last4)
        case .bankAccount:
            guard let last4 = paymentDetails.last4 else {
                return nil
            }
            let bankIconCode = PaymentSheetImageLibrary.bankIconCode(for: nil)
            guard let icon = PaymentSheetImageLibrary.bankInstitutionIcon(for: bankIconCode) else {
                fallthrough
            }
            self.init(icon: icon, last4: last4)
        case .unparsable:
            guard let display = paymentDetails.display else {
                return nil
            }
            let icon = Image.link_icon.makeImage()
            let displayText = display.sublabel ?? display.label
            self.init(icon: icon, last4: displayText, iconUrl: display.icon?.main)
        @unknown default:
            return nil
        }
    }
}

/// A SwiftUI image view that displays a static icon immediately and asynchronously loads a remote icon if a URL is provided.
@available(iOS 15.0, *)
struct LinkAsyncIconView: View {
    let staticIcon: UIImage
    let iconUrl: URL?
    let height: CGFloat

    @State private var downloadedIcon: UIImage?

    var body: some View {
        SwiftUI.Image(uiImage: downloadedIcon ?? staticIcon)
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .task(id: iconUrl) {
                guard let url = iconUrl else { return }
                downloadedIcon = try? await DownloadManager.sharedManager.downloadImage(url: url)
            }
    }
}
