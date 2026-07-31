//
//  LinkShippingAddressRow.swift
//  StripePaymentSheet
//

import UIKit

@_spi(STP) import StripeUICore

/// A tappable row for the wallet view showing the currently selected shipping address with a `>` push indicator.
final class LinkShippingAddressRow: UIControl {

    private enum Constants {
        static let contentSpacing: CGFloat = 16
        static let chevronSize: CGSize = .init(width: 24, height: 24)
        static let insets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
    }

    private lazy var sectionLabel: UILabel = {
        let label = UILabel()
        label.text = STPLocalizedString(
            "Shipping",
            "Label for the shipping address section in the Link wallet."
        )
        label.font = LinkUI.font(forTextStyle: .body)
        label.textColor = .linkTextTertiary
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var addressSummaryLabel: UILabel = {
        let label = UILabel()
        label.font = LinkUI.font(forTextStyle: .bodyEmphasized)
        label.textColor = .linkTextPrimary
        label.numberOfLines = 1
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }()

    private lazy var chevron: UIImageView = {
        let image = UIImage(systemName: "chevron.right")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold))
            .withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: image)
        imageView.tintColor = .linkTextTertiary
        imageView.contentMode = .center
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: Constants.chevronSize.width),
            imageView.heightAnchor.constraint(equalToConstant: Constants.chevronSize.height),
        ])
        return imageView
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [sectionLabel, addressSummaryLabel, chevron])
        stack.axis = .horizontal
        stack.spacing = Constants.contentSpacing
        stack.alignment = .center
        stack.directionalLayoutMargins = Constants.insets
        stack.isLayoutMarginsRelativeArrangement = true

        let labelWidth = sectionLabel.widthAnchor.constraint(
            equalToConstant: LinkPaymentMethodPicker.widthForHeaderLabels
        )
        labelWidth.priority = .defaultLow
        labelWidth.isActive = true

        return stack
    }()

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.7 : 1 }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addAndPinSubview(stackView)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addAndPinSubview(stackView)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled && !isHidden && alpha > 0.01 && self.point(inside: point, with: event) else {
            return nil
        }
        return self
    }

    func configure(with address: ShippingAddressesResponse.ShippingAddress?) {
        if let address {
            addressSummaryLabel.text = address.formattedShortSummary
            addressSummaryLabel.textColor = .linkTextPrimary
        } else {
            addressSummaryLabel.text = STPLocalizedString(
                "Select address",
                "Placeholder for when no shipping address is selected in the Link wallet."
            )
            addressSummaryLabel.textColor = .linkTextBrand
        }
    }
}
