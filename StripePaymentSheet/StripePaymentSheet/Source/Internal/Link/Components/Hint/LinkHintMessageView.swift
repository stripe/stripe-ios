//
//  LinkHintMessageView.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 8/14/25.
//

@_spi(STP) import StripeUICore
import UIKit

/// For internal SDK use only
@objc(STP_Internal_LinkHintMessageView)
final class LinkHintMessageView: UIView {
    private struct Constants {
        static let spacing: CGFloat = LinkUI.smallContentSpacing
        static let margins: NSDirectionalEdgeInsets = LinkUI.compactButtonMargins
        static let iconSize: CGSize = .init(width: 16, height: 16)
        static let cornerRadius: CGFloat = LinkUI.cornerRadius
        static let minimumHeight: CGFloat = LinkUI.minimumButtonHeight
    }
    var text: String? {
        get {
            return textLabel.text
        }
        set {
            textLabel.text = newValue
        }
    }
    private lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .linkIconTertiary
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: Constants.iconSize.width),
            imageView.heightAnchor.constraint(equalToConstant: Constants.iconSize.height),
        ])

        return imageView
    }()

    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.textColor = .linkTextTertiary
        label.font = LinkUI.font(forTextStyle: .detail)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()
    init(message: String) {
        super.init(frame: .zero)
        setupUI()
        configureImage()
        self.text = message
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let stackView = UIStackView(arrangedSubviews: [iconView, textLabel])

        stackView.axis = .horizontal
        stackView.spacing = Constants.spacing
        stackView.alignment = .center
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = Constants.margins
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        backgroundColor = .linkSurfaceSecondary
        layer.cornerRadius = Constants.cornerRadius

        heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.minimumHeight).isActive = true
    }
    private func configureImage() {
        iconView.image = Image.icon_info.makeImage(template: true)
    }
}
