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
        static let minimumHeight: CGFloat = LinkUI.minimumButtonHeight
    }

    enum Style {
        case filled
        case outlined
        case error

        var backgroundColor: UIColor {
            switch self {
            case .filled:
                return .linkSurfaceSecondary
            case .outlined, .error:
                return .linkSurfacePrimary
            }
        }

        var textColor: UIColor {
            switch self {
            case .filled:
                return .linkTextTertiary
            case .outlined:
                return .linkOutlinedHintMessageForeground
            case .error:
                return .linkTextCritical
            }
        }

        var textStyle: LinkUI.TextStyle {
            switch self {
            case .filled, .outlined:
                    .detail
            case .error:
                    .caption
            }
        }

        var iconColor: UIColor {
            switch self {
            case .filled, .outlined:
                UIColor.linkIconTertiary
            case .error:
                UIColor.linkTextCritical
            }
        }

        var icon: Image {
            switch self {
            case .filled, .outlined:
                Image.icon_info
            case .error:
                Image.icon_link_warning_circle
            }
        }

        var isBordered: Bool {
            switch self {
            case .filled:
                false
            case .outlined, .error:
                true
            }
        }

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
        imageView.tintColor = style.iconColor
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
        label.textColor = style.textColor
        label.font = LinkUI.font(forTextStyle: style.textStyle)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    private let style: Style

    init(message: String?, style: Style) {
        self.style = style
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
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        backgroundColor = style.backgroundColor

        applyOutlineIfNecessary()

        if let cornerRadius = LinkUI.appearance.cornerRadius {
            layer.cornerRadius = cornerRadius
        } else {
            ios26_applyDefaultCornerConfiguration()
        }

        heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.minimumHeight).isActive = true
    }

    private func applyOutlineIfNecessary() {
        if style.isBordered {
            layer.borderColor = UIColor.linkOutlinedHintMessageBorder.cgColor
            layer.borderWidth = 1.0
        }
    }

    private func configureImage() {
        iconView.image = style.icon.makeImage(template: true)
    }

    #if !os(visionOS)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyOutlineIfNecessary()
    }
    #endif
}

@available(iOS 17.0, *)
#Preview {

    let stackView = UIStackView(arrangedSubviews: [

        LinkHintMessageView(message: "Some short text.", style: .filled),
        LinkHintMessageView(message: "Medium text that stretches a little farther.", style: .filled),
        LinkHintMessageView(message: "Here's a really long message that we can use for testing. It even spans multiple lines.", style: .filled),

        LinkHintMessageView(message: "Some short text.", style: .outlined),
        LinkHintMessageView(message: "Medium text that stretches a little farther.", style: .outlined),
        LinkHintMessageView(message: "Here's a really long message that we can use for testing. It even spans multiple lines.", style: .outlined),

        LinkHintMessageView(message: "Something went wrong", style: .error),
        LinkHintMessageView(message: "There was an error connecting to Stripe.", style: .error),
        LinkHintMessageView(message: "Here's a really long message that we can use for testing. It even spans multiple lines.", style: .error),

    ])

    stackView.axis = .vertical
    stackView.spacing = 5
    stackView.distribution = .fillEqually

    return stackView

}
