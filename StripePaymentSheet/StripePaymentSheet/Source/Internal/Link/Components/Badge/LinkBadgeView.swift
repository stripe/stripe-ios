//
//  LinkBadgeView.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 4/29/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripeUICore

/// For internal SDK use only
@objc(STP_Internal_LinkBadgeView)
final class LinkBadgeView: UIView {
    struct Constants {
        static let spacing: CGFloat = 4
        static let margins: NSDirectionalEdgeInsets = .insets(top: 2, leading: 4, bottom: 2, trailing: 4)
        static let iconSize: CGSize = .init(width: 12, height: 12)
        static let maxFontSize: CGFloat = 16
    }

    enum BadgeType {
        case neutral
        case error
    }

    let type: BadgeType

    var text: String? {
        get {
            return textLabel.text
        }
        set {
            textLabel.text = newValue
        }
    }

    private lazy var iconView: UIImageView? = {
        guard let icon = type.icon else {
            return nil
        }

        let imageView = UIImageView(image: icon)
        imageView.tintColor = type.foregroundColor
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.isHidden = imageView.image == nil

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: Constants.iconSize.width),
            imageView.heightAnchor.constraint(equalToConstant: Constants.iconSize.height),
        ])

        return imageView
    }()

    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.textColor = type.foregroundColor
        label.font = LinkUI.font(forTextStyle: .captionEmphasized, maximumPointSize: Constants.maxFontSize)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 20)
    }

    convenience init(type: BadgeType, text: String) {
        self.init(type: type)
        self.text = text
    }

    init(type: BadgeType) {
        self.type = type
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        setContentHuggingPriority(.required, for: .vertical)
        setContentHuggingPriority(.required, for: .horizontal)

        let stackView = UIStackView(arrangedSubviews: [iconView, textLabel].compactMap({ $0 }))

        stackView.axis = .horizontal
        stackView.spacing = Constants.spacing
        stackView.alignment = .center
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = Constants.margins
        addAndPinSubview(stackView)

        backgroundColor = type.backgroundColor
        layer.cornerRadius = LinkUI.smallCornerRadius
    }

}

private extension LinkBadgeView.BadgeType {

    var icon: UIImage? {
        switch self {
        case .neutral:
            return nil
        case .error:
            return Image.icon_link_error.makeImage(template: true)
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .neutral:
            return .linkNeutralBackground
        case .error:
            return .linkDangerBackground
        }
    }

    var foregroundColor: UIColor {
        switch self {
        case .neutral:
            return .linkNeutralForeground
        case .error:
            return .linkDangerForeground
        }
    }

}
