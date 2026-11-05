//
//  LinkCardBrandView.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 8/31/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(InternalOnlyAPI) import StripePayments
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

/// A view that displays a card brand icon/logo, sized to match the legacy padded card brand icons.
final class LinkCardBrandView: UIView {

    /// The size of legacy icons.
    private static let legacyIconSize = CGSize(width: 29, height: 19)

    /// The target size of the rectangular part of the icon.
    static let targetIconSize = CGSize(width: 24, height: 16)

    /// Padding built in to the icon.
    ///
    /// Card brand icons have baked-in top and right padding, so they align perfectly with the CVC icons. Bottom padding
    /// is then added for vertically centering the icon; thus it must match the top padding.
    private static let iconPadding = UIEdgeInsets(top: 2, left: 0, bottom: 0, right: 3)
    private var centeringPadding: UIEdgeInsets {
        return UIEdgeInsets(
            top: 0,
            left: centerHorizontally ? Self.iconPadding.right : 0,
            bottom: Self.iconPadding.top,
            right: 0
        )
    }

    /// Card brand to display.
    private var cardBrand: STPCardBrand = .unknown {
        didSet {
            updateIcon()
        }
    }

    /// If `true`, will center the card brand icon horizontally in the containing view
    let centerHorizontally: Bool

    override var intrinsicContentSize: CGSize {
        return size(for: Self.targetIconSize)
    }

    func size(for targetSize: CGSize) -> CGSize {
        let padding = centeringPadding

        // The way this scaling works isn't perfect since the returned size has to map to a valid point value
        // (see rounding) which can change the effects of scaleX/scaleY. In practice this is only 1 pixel off so
        // acceptable for now.
        let scaleX =
            targetSize.width
            / (Self.legacyIconSize.width - Self.iconPadding.left - Self.iconPadding.right)
        let scaleY =
            targetSize.height
            / (Self.legacyIconSize.height - Self.iconPadding.top - Self.iconPadding.bottom)
        #if os(visionOS)
        let screenScale = 1.0
        #else
        let screenScale = UIScreen.main.scale
        #endif
        return CGSize(
            width: (round(Self.legacyIconSize.width * scaleX * screenScale) / screenScale)
                + padding.right + padding.left,
            height: (round(Self.legacyIconSize.height * scaleY * screenScale) / screenScale)
                + padding.top + padding.bottom
        )
    }

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    init(centerHorizontally: Bool = false) {
        self.centerHorizontally = centerHorizontally
        super.init(frame: .zero)

        addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: centeringPadding.top),
            bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: centeringPadding.bottom),
            imageView.leftAnchor.constraint(equalTo: leftAnchor, constant: centeringPadding.left),
            imageView.rightAnchor.constraint(equalTo: rightAnchor, constant: centeringPadding.right),
        ])

        updateIcon()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCardBrand(_ brand: STPCardBrand) {
        cardBrand = brand
    }

    private func updateIcon() {
        imageView.image = PaymentSheetImageLibrary.cardBrandImage(for: cardBrand)
    }

#if !os(visionOS)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateIcon()
    }
#endif
}
