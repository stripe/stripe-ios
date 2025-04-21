//
//  LinkNoticeView.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 3/30/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripeUICore

/// A view for displaying text notices.
///
/// For internal SDK use only
@objc(STP_Internal_LinkNoticeView)
final class LinkNoticeView: UIView {
    struct Constants {
        static let spacing: CGFloat = 10
        static let margins: NSDirectionalEdgeInsets = .insets(amount: 12)
    }

    enum NoticeType {
        case error
    }

    let type: NoticeType

    var text: String? {
        get {
            return textLabel.text
        }
        set {
            textLabel.text = newValue
        }
    }

    private lazy var iconView: UIImageView = {
        let imageView = UIImageView(image: type.icon)
        imageView.tintColor = type.foregroundColor
        imageView.adjustsImageSizeForAccessibilityContentSizeCategory = true
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        return imageView
    }()

    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.textColor = type.foregroundColor
        label.numberOfLines = 0
        label.font = LinkUI.font(forTextStyle: .detail)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    convenience init(type: NoticeType, text: String) {
        self.init(type: type)
        self.text = text
    }

    init(type: NoticeType) {
        self.type = type
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let stackView = UIStackView(arrangedSubviews: [
            iconView,
            textLabel,
        ])

        stackView.axis = .horizontal
        stackView.spacing = Constants.spacing
        stackView.alignment = .top
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = Constants.margins
        addAndPinSubview(stackView)

        backgroundColor = type.backgroundColor
        layer.cornerRadius = LinkUI.mediumCornerRadius
    }

}

private extension LinkNoticeView.NoticeType {

    var icon: UIImage {
        switch self {
        case .error:
            return Image.icon_link_error.makeImage(template: true)
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .error:
            return .linkDangerBackground
        }
    }

    var foregroundColor: UIColor {
        switch self {
        case .error:
            return .linkDangerForeground
        }
    }

}
