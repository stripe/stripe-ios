//
//  LinkSheetNavigationBar.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 3/10/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

/// For internal SDK use only
@objc(STP_Internal_LinkSheetNavigationBar)
class LinkSheetNavigationBar: SheetNavigationBar {
    private let brand: LinkBrand

    private lazy var logoView: UIImageView = {
        let imageView = UIImageView(image: brand.paymentSheetLogoImage)
        imageView.tintColor = .linkIconBrand
        imageView.isAccessibilityElement = true
        imageView.accessibilityTraits = .header
        imageView.accessibilityLabel = brand.accessibilityDisplayName
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = appearance.scaledFont(for: appearance.font.base.medium, style: .headline, maximumPointSize: 20)
        label.textColor = appearance.colors.text
        label.textAlignment = .center
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private var titleCenterXConstraint: NSLayoutConstraint?
    private var titleBoundaryConstraints: [NSLayoutConstraint] = []

    var title: String? {
        didSet {
            titleLabel.text = title
            titleLabel.isHidden = title == nil || title?.isEmpty == true
            updateTitleConstraints()
        }
    }

    override var leadingElement: UIView {
        if !logoView.isHidden {
            return logoView
        }
        return super.leadingElement
    }

    init(isTestMode: Bool, appearance: PaymentSheet.Appearance, brand: LinkBrand, shouldLogPaymentSheetAnalyticsOnDismissal: Bool = true) {
        self.brand = brand
        super.init(
            isTestMode: isTestMode,
            appearance: appearance,
            shouldLogPaymentSheetAnalyticsOnDismissal: shouldLogPaymentSheetAnalyticsOnDismissal
        )

        logoView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(logoView)

        NSLayoutConstraint.activate([
            logoView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: LinkUI.contentMargins.leading),
            logoView.centerYAnchor.constraint(equalTo: centerYAnchor),
            logoView.heightAnchor.constraint(equalToConstant: 24),
        ])

        addSubview(titleLabel)

        let titleCenterXConstraint = titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        self.titleCenterXConstraint = titleCenterXConstraint
        titleBoundaryConstraints = makeTitleBoundaryConstraints()

        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleCenterXConstraint,
        ] + titleBoundaryConstraints)
        titleLabel.isHidden = true
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: LinkUI.navigationBarHeight)
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func createBackButton() -> UIButton {
        let image = Image.icon_chevron_left_standalone.makeImage(template: true)
            .imageFlippedForRightToLeftLayoutDirection()
        return Self.createButton(
            with: image,
            accessibilityLabel: String.Localized.back,
            accessibilityIdentifier: "UIButton.Back",
            appearance: appearance
        )
    }

    override func createCloseButton() -> UIButton {
        return Self.createCloseButton(
            accessibilityIdentifier: "UIButton.Close",
            appearance: appearance
        )
    }

    static func createCloseButton(
        accessibilityIdentifier: String,
        appearance: PaymentSheet.Appearance
    ) -> UIButton {
        let image = Image.icon_x_standalone.makeImage(template: true)
        return createButton(
            with: image,
            accessibilityLabel: String.Localized.close,
            accessibilityIdentifier: accessibilityIdentifier,
            appearance: appearance
        )
    }

    private static func createButton(
        with image: UIImage,
        accessibilityLabel: String,
        accessibilityIdentifier: String,
        appearance: PaymentSheet.Appearance
    ) -> UIButton {
        let resizedImage = image.resized(to: CGSize(width: LinkUI.navigationBarButtonContentSize, height: LinkUI.navigationBarButtonContentSize))
        let button = SheetNavigationButton(type: .custom)
        button.setImage(resizedImage ?? image, for: .normal)
        button.tintColor = appearance.colors.icon
        button.contentMode = .scaleAspectFit
        button.accessibilityLabel = accessibilityLabel
        button.accessibilityIdentifier = accessibilityIdentifier

        button.translatesAutoresizingMaskIntoConstraints = false

        if appearance.navigationBarStyle.isGlass {
            button.ios26_applyGlassConfiguration()
        } else {
            // Add a background color and center the icon within it
            let size = LinkUI.navigationBarButtonSize

            // Create circular background
            button.backgroundColor = .linkSurfaceSecondary
            button.layer.cornerRadius = size / 2

            // Constrain the button size
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: size),
                button.heightAnchor.constraint(equalToConstant: size),
            ])
        }

        return button
    }

    override func setStyle(_ style: SheetNavigationBar.Style) {
        super.setStyle(style)
        if case .back = style {
            logoView.isHidden = true
        } else {
            logoView.isHidden = false
        }

        updateTitleConstraints()
    }

    private func updateTitleConstraints() {
        guard let titleCenterXConstraint, !titleLabel.isHidden else { return }

        // Update boundary constraints to the latest buttons and layout direction.
        NSLayoutConstraint.deactivate(titleBoundaryConstraints)
        titleBoundaryConstraints = makeTitleBoundaryConstraints()
        NSLayoutConstraint.activate(titleBoundaryConstraints)

        // Check if title fits with center constraint, otherwise remove it to prevent layout conflicts.
        //
        // When title is short, we want it centered:
        // [Button]        [Title]        [Button]
        //
        // When title is too long, centering would conflict with leading/trailing constraints,
        // so we remove the center constraint and let it align to the leading edge:
        // [Button] [ Very Long Title Message .. ]

        // This method is called initially the width of the view is 0.
        // Activitating the constraint system at this time causes a layout conflict since nothing can layout in width 0.
        // Hold off on laying anything out until self has width.
        if bounds.width > 0 {
            layoutIfNeeded()
        }
        let titleSize = titleLabel.sizeThatFits(
            CGSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: titleLabel.bounds.height
            )
        )
        let availableWidth = calculateAvailableWidthForTitle()

        if titleSize.width > availableWidth {
            // Title is too long - remove center constraint to prevent conflicts
            titleCenterXConstraint.isActive = false
            titleLabel.textAlignment = .natural
        } else {
            // Title fits - keep it centered for better visual balance
            titleCenterXConstraint.isActive = true
            titleLabel.textAlignment = .center
        }
    }

    private func calculateAvailableWidthForTitle() -> CGFloat {
        let elements = titleBoundaryElements
        let leftBoundary = (elements.left?.frame.maxX ?? bounds.minX)
            + (elements.left == nil ? 0 : LinkUI.contentSpacing)
        let rightBoundary = (elements.right?.frame.minX ?? bounds.maxX)
            - (elements.right == nil ? 0 : LinkUI.contentSpacing)
        return max(0, rightBoundary - leftBoundary)
    }

    private func makeTitleBoundaryConstraints() -> [NSLayoutConstraint] {
        let elements = titleBoundaryElements
        let leftBoundary = titleLabel.leftAnchor.constraint(
            greaterThanOrEqualTo: elements.left?.rightAnchor ?? leftAnchor,
            constant: elements.left == nil ? 0 : LinkUI.contentSpacing
        )
        let rightBoundary = titleLabel.rightAnchor.constraint(
            lessThanOrEqualTo: elements.right?.leftAnchor ?? rightAnchor,
            constant: elements.right == nil ? 0 : -LinkUI.contentSpacing
        )
        return [leftBoundary, rightBoundary]
    }

    private var titleBoundaryElements: (left: UIView?, right: UIView?) {
        if effectiveUserInterfaceLayoutDirection == .rightToLeft {
            return (trailingElement, leadingElement)
        }
        return (leadingElement, trailingElement)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateTitleConstraints()
    }
}
