//
//  RemoveButton.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 1/22/25.
//

import Foundation
import PassKit
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif

/// Remove button
/// For internal SDK use only
@objc(STP_Internal_RemoveButton)
class RemoveButton: UIButton {
    private let paymentSheetAppearance: PaymentSheet.Appearance

    override var intrinsicContentSize: CGSize {
        return CGSize(
            width: UIView.noIntrinsicMetric,
            height: paymentSheetAppearance.primaryButton.height
        )
    }

    init(
        title: String = .Localized.remove,
        appearance: PaymentSheet.Appearance
    ) {
        self.paymentSheetAppearance = appearance
        super.init(frame: .zero)

        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)

        let font = appearance.primaryButton.font ?? appearance.scaledFont(for: appearance.font.base.medium, style: .callout, maximumPointSize: 25)
        setTitleColor(appearance.colors.danger, for: .normal)
        setTitleColor(appearance.colors.danger.disabledColor, for: .highlighted)
        layer.borderColor = appearance.colors.danger.cgColor
        setTitle(title, for: .normal)
        titleLabel?.textAlignment = .center
        titleLabel?.font = font
        titleLabel?.adjustsFontForContentSizeCategory = true
        applyCornerRadiusOrConfiguration(for: appearance, ios26DefaultCornerStyle: .capsule, shouldUsePrimaryButtonCornerRadius: true)
        // Workaround:  Use layer.borderWidth because background.strokeWidth isn't compatible with .capsule()
        layer.borderWidth = 1.5

        addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside])
    }

    @objc private func buttonTouchDown(_: UIButton) {
        configuration?.attributedTitle?.foregroundColor = paymentSheetAppearance.colors.danger.disabledColor
        configuration?.background.strokeColor = paymentSheetAppearance.colors.danger.disabledColor
    }

    @objc private func buttonTouchUp(_: UIButton) {
        configuration?.attributedTitle?.foregroundColor = paymentSheetAppearance.colors.danger
        configuration?.background.strokeColor = paymentSheetAppearance.colors.danger
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
