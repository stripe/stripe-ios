//
//  CardBrandView.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 8/31/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

/// A view that displays a card brand icon/logo, or an icon to help the user locate the CVC
/// for a specific card brand.
/// For internal SDK use only
@objc(STP_Internal_CardBrandView)
@_spi(STP) public final class CardBrandView: UIView {

    // TODO(ramont): unify icon sizes.

    /// The size of legacy icons.
    private static let legacyIconSize = CGSize(width: 29, height: 19)

    /// The target size of the rectangular part of the icon.
    /// internal so we can reuse size with other icon views (see LinkPaymentMethodPicker-CellContentView)
    @_spi(STP) public static let targetIconSize = CGSize(width: 24, height: 16)

    /// Padding built in to the icon.
    ///
    /// Card brand icons have baked-in top and right padding, so they align perfectly with the CVC icons. Bottom padding
    /// is then added for vertically centering the icon; thus it must match the top padding.
    ///
    ///  ```
    ///  +----------------+
    ///  |  PADDING       |
    ///  +------------+   |
    ///  |            |   |
    ///  |    LOGO    |   |
    ///  |            |   |
    ///  +------------+---+
    ///  |  B. PADDING    |
    ///  +----------------+
    ///  ```
    ///
    /// TODO(ramont): remove baked-in padding and perform alignment in code.
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
    var cardBrand: STPCardBrand = .unknown {
        didSet {
            updateIcon()
        }
    }

    /// If `true`, the view will display the CVC hint icon instead of the card brand image.
    let showCVC: Bool

    /// If `true`, will center the card brand icon horizontally in the containing view
    let centerHorizontally: Bool

    @_spi(STP) public override var intrinsicContentSize: CGSize {
        return size(for: Self.targetIconSize)
    }

    @_spi(STP) public func size(for targetSize: CGSize) -> CGSize {
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
        // We could adapt this for multiple screens, but probably not worth it (better solution is to remove padding from images)
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

    /// Creates and returns an initialized card brand view.
    /// - Parameter showCVC: Whether or not to show the CVC hint icon instead of the card brand image.
    @_spi(STP) public init(
        showCVC: Bool = false,
        centerHorizontally: Bool = false
    ) {
        self.showCVC = showCVC
        self.centerHorizontally = centerHorizontally
        super.init(frame: .zero)

        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: self.topAnchor, constant: centeringPadding.top),
            self.bottomAnchor.constraint(
                equalTo: imageView.bottomAnchor,
                constant: centeringPadding.bottom
            ),
            imageView.leftAnchor.constraint(
                equalTo: self.leftAnchor,
                constant: centeringPadding.left
            ),
            imageView.rightAnchor.constraint(
                equalTo: self.rightAnchor,
                constant: centeringPadding.right
            ),
        ])

        updateIcon()
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }

    @_spi(STP) public func setCardBrand(_ brand: STPCardBrand) {
        self.cardBrand = brand
    }

    // MARK: - Private Methods

    private func updateIcon() {
        imageView.image = image(for: cardBrand)
    }

    /// Returns the most appropriate icon/image for the given card brand.
    /// - Parameter cardBrand: Card brand
    /// - Returns: Image.
    private func image(for brand: STPCardBrand) -> UIImage {
        if showCVC {
            return STPImageLibrary.cvcImage(for: brand)
        }
        return STPImageLibrary.cardBrandImage(for: brand)
    }

    // MARK: - Callbacks
#if !os(visionOS)
    @_spi(STP) public override func traitCollectionDidChange(
        _ previousTraitCollection: UITraitCollection?
    ) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateIcon()
    }
#endif
}
