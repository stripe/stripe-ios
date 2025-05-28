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
        contentStackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let changeButton = UILabel()
        changeButton.translatesAutoresizingMaskIntoConstraints = false
        changeButton.isUserInteractionEnabled = true
        changeButton.text = .Localized.change
        changeButton.textColor = theme.colors.primary
        changeButton.font = theme.fonts.footnote

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onChangeClick))
        changeButton.addGestureRecognizer(tapRecognizer)
        let stackView = UIStackView(arrangedSubviews: [contentStackView, changeButton])
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fill

        addAndPinSubview(stackView, insets: .insets(amount: 12))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func onChangeClick() {
        delegate?.linkDefaultOptInViewDidSelectChange(self)
    }
}
