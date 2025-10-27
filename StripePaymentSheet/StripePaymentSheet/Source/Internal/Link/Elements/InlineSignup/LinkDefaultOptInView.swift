//
//  LinkDefaultOptInView.swift
//  StripePaymentSheet
//
//  Created by Till Hellmund on 5/26/25.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol LinkDefaultOptInViewDelegate: AnyObject {
    func linkDefaultOptInViewDidSelectChange(_ view: LinkDefaultOptInView)
}

class LinkDefaultOptInView: UIView {
    weak var delegate: LinkDefaultOptInViewDelegate?

    init(
        email: String,
        phoneNumber: PhoneNumber,
        theme: ElementsAppearance
    ) {
        super.init(frame: .zero)

        let emailLabel = UILabel()
        emailLabel.text = email
        emailLabel.font = theme.fonts.footnote
        emailLabel.textColor = theme.colors.bodyText

        let phoneLabel = UILabel()
        phoneLabel.text = phoneNumber.string(as: .national)
        phoneLabel.font = theme.fonts.smallFootnote
        phoneLabel.textColor = theme.colors.secondaryText

        let contentStackView = UIStackView(arrangedSubviews: [emailLabel, phoneLabel])
        contentStackView.axis = .vertical
        contentStackView.isLayoutMarginsRelativeArrangement = true
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        contentStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let changeButton = UIButton(type: .system)
        changeButton.translatesAutoresizingMaskIntoConstraints = false
        changeButton.setTitle(.Localized.change, for: .normal)
        changeButton.titleLabel?.font = theme.fonts.footnote
        changeButton.setTitleColor(theme.colors.primary, for: .normal)
        changeButton.addTarget(self, action: #selector(onChangeClick), for: .touchUpInside)
        changeButton.setContentHuggingPriority(.required, for: .horizontal)
        changeButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        addSubview(contentStackView)
        addSubview(changeButton)

        NSLayoutConstraint.activate([
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),

            changeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            changeButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            contentStackView.trailingAnchor.constraint(equalTo: changeButton.leadingAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func onChangeClick() {
        delegate?.linkDefaultOptInViewDidSelectChange(self)
    }
}
