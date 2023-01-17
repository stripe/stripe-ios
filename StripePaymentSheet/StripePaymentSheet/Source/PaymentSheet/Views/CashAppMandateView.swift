//
//  CashAppMandateView.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 1/10/23.
//

@_spi(STP) import StripeUICore
import UIKit

/// For internal SDK use only
@objc(STP_Internal_CashAppMandateView)
class CashAppMandateView: UIView {
    private let theme: ElementsUITheme
    lazy var label: UILabel = {
        let label = UILabel()
        label.font = theme.fonts.caption
        label.textColor = theme.colors.secondaryText
        label.numberOfLines = 0
        return label
    }()

    init(merchantDisplayName: String, theme: ElementsUITheme = .default) {
        self.theme = theme
        super.init(frame: .zero)
        let localized = STPLocalizedString(
            "By continuing, you authorize %@ to debit your Cash App account for this payment and future payments in accordance with %@'s terms, until this authorization is revoked. You can change this anytime in your Cash App Settings.",
            "Cash App mandate text"
        )
        label.text = String(format: localized, merchantDisplayName, merchantDisplayName)
        installConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func installConstraints() {
        addAndPinSubview(label)
    }
}
