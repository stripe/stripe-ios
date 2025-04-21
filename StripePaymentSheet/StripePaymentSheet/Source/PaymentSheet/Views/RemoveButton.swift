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
import UIKit

/// Remove button
/// For internal SDK use only
@objc(STP_Internal_RemoveButton)
class RemoveButton: UIButton {
    private let appearance: PaymentSheet.Appearance
    private static let minimumLabelHeight: CGFloat = 24
    private static let minimumButtonHeight: CGFloat = 44

    override var intrinsicContentSize: CGSize {
        let height = Self.minimumLabelHeight
            + directionalLayoutMargins.top
            + directionalLayoutMargins.bottom

        return CGSize(
            width: UIView.noIntrinsicMetric,
            height: max(height, Self.minimumButtonHeight)
        )
    }

    init(
        title: String = .Localized.remove,
        appearance: PaymentSheet.Appearance = PaymentSheet.Appearance.default
    ) {
        self.appearance = appearance
        super.init(frame: .zero)

        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)

        let font = appearance.primaryButton.font ?? appearance.scaledFont(for: appearance.font.base.medium, style: .callout, maximumPointSize: 25)
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.bordered()
            config.baseBackgroundColor = .clear
            config.background.cornerRadius = appearance.cornerRadius
            config.background.strokeWidth = appearance.selectedBorderWidth ?? appearance.borderWidth * 1.5
            config.background.strokeColor = appearance.colors.danger
            config.titleAlignment = .center
            config.attributedTitle = AttributedString(title, attributes: AttributeContainer([.font: font, .foregroundColor: appearance.colors.danger]))
            configuration = config
        } else {
            setTitleColor(appearance.colors.danger, for: .normal)
            setTitleColor(appearance.colors.danger.disabledColor, for: .highlighted)
            layer.borderColor = appearance.colors.danger.cgColor
            layer.borderWidth = appearance.selectedBorderWidth ?? appearance.borderWidth * 1.5
            layer.cornerRadius = appearance.cornerRadius
            setTitle(title, for: .normal)
            titleLabel?.textAlignment = .center
            titleLabel?.font = font
            titleLabel?.adjustsFontForContentSizeCategory = true
        }
        addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside])
    }

    @objc private func buttonTouchDown(_: UIButton) {
        if #available(iOS 15.0, *)  {
            configuration?.attributedTitle?.foregroundColor = appearance.colors.danger.disabledColor
            configuration?.background.strokeColor = appearance.colors.danger.disabledColor
        }
        else {
            setTitleColor(appearance.colors.danger.disabledColor, for: .normal)
            layer.borderColor = appearance.colors.danger.disabledColor.cgColor
        }
    }

    @objc private func buttonTouchUp(_: UIButton) {
        if #available(iOS 15.0, *)  {
            configuration?.attributedTitle?.foregroundColor = appearance.colors.danger
            configuration?.background.strokeColor = appearance.colors.danger
        }
        else {
            setTitleColor(appearance.colors.danger, for: .normal)
            layer.borderColor = appearance.colors.danger.cgColor
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
