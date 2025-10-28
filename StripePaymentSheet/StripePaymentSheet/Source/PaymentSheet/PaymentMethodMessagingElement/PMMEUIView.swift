//
//  PMMEUIView.swift
//  StripePaymentSheet
//
//  Created by George Birch on 10/9/25.
//

import SafariServices
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

class PMMEUIView: UIStackView {

    private let mode: PaymentMethodMessagingElement.Mode
    private let infoUrl: URL
    private let promotion: String
    private let appearance: PaymentMethodMessagingElement.Appearance

    private static let horizontalPadding: CGFloat = 8
    private static let verticalPadding: CGFloat = 8

    private var logoViews = [UIImageView]()
    private let promotionLabel = UILabel()

    // Callback to notify SwiftUI of height changes. Unneeded if used in a UIKit context.
    private let didUpdateHeight: ((CGFloat) -> Void)?
    private var previousHeight: CGFloat?

    init(viewData: PaymentMethodMessagingElement.ViewData, didUpdateHeight: ((CGFloat) -> Void)? = nil) {
        self.mode = viewData.mode
        self.infoUrl = viewData.infoUrl
        self.promotion = viewData.promotion
        self.appearance = viewData.appearance
        self.didUpdateHeight = didUpdateHeight
        super.init(frame: .zero)

        setupView()

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
    }

    // Would be great to have a localized accessibility hint saying you can to open the info webview.
    private func setupView() {
        axis = .vertical
        spacing = Self.verticalPadding

        if case .alwaysDark = appearance.style {
            overrideUserInterfaceStyle = .dark
        } else if case .alwaysLight = appearance.style {
            overrideUserInterfaceStyle = .light
        }

        // Add logos if in multi-partner style
        if case .multiPartner(let logoSets) = mode {
            let logoStack = UIStackView()
            logoStack.axis = .horizontal
            logoStack.spacing = Self.horizontalPadding
            for logoSet in logoSets {
                // Empty placeholder for initialization, we'll populate with the correct light/dark asset in willMove()
                let imageView = ScalingImageView(appearance: appearance)
                imageView.contentMode = .left
                imageView.contentMode = .scaleAspectFill
                imageView.accessibilityLabel = logoSet.altText
                imageView.isAccessibilityElement = true
                logoStack.addArrangedSubview(imageView)
                logoViews.append(imageView)
            }
            logoStack.addArrangedSubview(UIView()) // spacer view to push icons to leading edge
            addArrangedSubview(logoStack)
        }

        promotionLabel.attributedText = getPromotionAttributedString()
        promotionLabel.adjustsFontForContentSizeCategory = true
        promotionLabel.numberOfLines = 0
        addArrangedSubview(promotionLabel)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        updateLogoStyles()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateLogoStyles()
        promotionLabel.attributedText = getPromotionAttributedString()
        // icon view scales may have changed
        logoViews.forEach { $0.invalidateIntrinsicContentSize() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Calculate our natural height
        let desiredHeight = systemLayoutSizeFitting(CGSize(width: frame.width, height: UIView.layoutFittingCompressedSize.height)).height

        // Notify if changed
        if desiredHeight != previousHeight {
            didUpdateHeight?(desiredHeight)
            self.previousHeight = desiredHeight
        }
    }

    private func updateLogoStyles() {
        guard case .multiPartner(let imageSets) = mode else { return }
        for (logoSet, logoViews) in zip(imageSets, logoViews) {
            // If we are in alwaysLight, alwaysDark, or flat, dark and light will both be populated with the appropriate asset
            logoViews.image = traitCollection.isDarkMode ? logoSet.dark : logoSet.light
        }
    }

    private func getPromotionAttributedString() -> NSMutableAttributedString? {
        switch mode {
        case .singlePartner(let logoSet):
            return NSMutableAttributedString.bnplPromoString(
                font: appearance.scaledFont,
                textColor: appearance.textColor,
                infoIconColor: appearance.infoIconColor ?? appearance.textColor,
                template: promotion,
                substitution: ("{partner}", traitCollection.isDarkMode ? logoSet.dark : logoSet.light)
            )
        case .multiPartner:
            return NSMutableAttributedString.bnplPromoString(
                font: appearance.scaledFont,
                textColor: appearance.textColor,
                infoIconColor: appearance.infoIconColor ?? appearance.textColor,
                template: promotion,
                substitution: nil
            )
        }
    }

    @objc private func didTap() {
        // Construct themed info url
        let themeParam = switch (appearance.style, traitCollection.isDarkMode) {
        case (.alwaysLight, _), (.automatic, false): "stripe"
        case (.alwaysDark, _), (.automatic, true): "night"
        case (.flat, _): "flat"
        }

        let queryParam = URLQueryItem(name: "theme", value: themeParam)
        guard var urlComponents = URLComponents(url: infoUrl, resolvingAgainstBaseURL: false) else {
            stpAssertionFailure("Unable to generate URL components")
            return
        }
        if urlComponents.queryItems == nil {
            urlComponents.queryItems = [queryParam]
        } else {
            urlComponents.queryItems?.append(queryParam)
        }
        guard let themedUrl = urlComponents.url else {
            stpAssertionFailure("Unable to generate themed URL")
            return
        }

        // Launch themed info url
        let safariController = SFSafariViewController(url: themedUrl)
        safariController.modalPresentationStyle = .formSheet
        window?.findTopMostPresentedViewController()?.present(safariController, animated: true)
    }
}

// UIImageView that scales according to the appearance's font size (including dynamic type)
class ScalingImageView: UIImageView {

    let appearance: PaymentMethodMessagingElement.Appearance

    init(appearance: PaymentMethodMessagingElement.Appearance) {
        self.appearance = appearance
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        guard let image else { return CGSize(width: -1, height: -1) }
        return image.sizeMatchingFont(appearance.scaledFont, additionalScale: 2.0)
    }
}
