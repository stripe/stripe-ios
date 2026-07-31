//
//  LinkShippingAddressCell.swift
//  StripePaymentSheet
//

import UIKit

final class LinkShippingAddressCell: UIControl {

    struct Constants {
        static let margins = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        static let contentSpacing: CGFloat = 12
        static let separatorHeight: CGFloat = 0.5
    }

    override var isHighlighted: Bool {
        didSet { setNeedsLayout() }
    }

    override var isSelected: Bool {
        didSet {
            radioButton.isOn = isSelected
            setNeedsLayout()
        }
    }

    private let radioButton = LinkPaymentMethodPicker.RadioButton()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = LinkUI.font(forTextStyle: .bodyEmphasized)
        label.textColor = .linkTextPrimary
        label.numberOfLines = 1
        return label
    }()

    private lazy var addressLabel: UILabel = {
        let label = UILabel()
        label.font = LinkUI.font(forTextStyle: .body)
        label.textColor = .linkTextSecondary
        label.numberOfLines = 0
        return label
    }()

    private lazy var textStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [nameLabel, addressLabel])
        stack.axis = .vertical
        stack.spacing = 2
        return stack
    }()

    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [radioButton, textStackView])
        stack.axis = .horizontal
        stack.spacing = Constants.contentSpacing
        stack.alignment = .center
        return stack
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .linkBorderDefault
        return view
    }()

    var showsSeparator: Bool = true {
        didSet { separatorView.isHidden = !showsSeparator }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        radioButton.translatesAutoresizingMaskIntoConstraints = false
        radioButton.setContentHuggingPriority(.required, for: .horizontal)
        radioButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStackView)

        separatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separatorView)

        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.margins.top),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.margins.bottom),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.margins.leading),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.margins.trailing),

            separatorView.heightAnchor.constraint(equalToConstant: Constants.separatorHeight),
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return bounds.contains(point) ? self : nil
    }

    func configure(with shippingAddress: ShippingAddressesResponse.ShippingAddress) {
        nameLabel.text = shippingAddress.address.name
        nameLabel.isHidden = (shippingAddress.address.name ?? "").isEmpty
        addressLabel.text = shippingAddress.formattedCellAddress
        radioButton.isOn = isSelected
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        alpha = isHighlighted ? 0.7 : 1
    }
}
