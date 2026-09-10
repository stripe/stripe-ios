//
//  LinkAppearance+CryptoOnramp.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/10/26.
//

#if DEBUG
@_spi(CryptoOnrampAlpha) import StripePaymentSheet
import UIKit

extension LinkAppearance {

    /// Standard appearance constant used in SwiftUI previews.
    static let previewLinkApperance = LinkAppearance(
        colors: .init(
            primary: UIColor(red: 171/255.0, green: 159/255.0, blue: 242/255.0, alpha: 1),
            contentOnPrimary: UIColor(red: 29/255.0, green: 18/255.0, blue: 56/255.0, alpha: 1),
            selectedBorder: .label
        ),
        primaryButton: .init(cornerRadius: 16, height: 56),
        style: .automatic,
        reduceLinkBranding: true
    )
}

#endif
