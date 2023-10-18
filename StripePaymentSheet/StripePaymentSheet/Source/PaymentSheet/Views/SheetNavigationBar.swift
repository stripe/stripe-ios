//
//  SheetNavigationBar.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 10/19/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol SheetNavigationBarDelegate: AnyObject {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar)
    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar)
}

/// For internal SDK use only
@objc(STP_Internal_SheetNavigationBar)
class SheetNavigationBar: UIView {
    static let height: CGFloat = 48
    weak var delegate: SheetNavigationBarDelegate?
    fileprivate lazy var leftItemsStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [closeButtonLeft, backButton, testModeView])
        stack.spacing = PaymentSheetUI.defaultPadding
        return stack
    }()
    fileprivate lazy var closeButtonLeft: UIButton = {
        let button = SheetNavigationButton(type: .custom)
        button.setImage(Image.icon_x_standalone.makeImage(template: true), for: .normal)
        button.tintColor = appearance.colors.icon
        button.accessibilityLabel = String.Localized.close
        button.accessibilityIdentifier = "UIButton.Close"
        return button
    }()

    fileprivate lazy var closeButtonRight: UIButton = {
        let button = SheetNavigationButton(type: .custom)
        button.setImage(Image.icon_x_standalone.makeImage(template: true), for: .normal)
        button.tintColor = appearance.colors.icon
        button.accessibilityLabel = String.Localized.close
        button.accessibilityIdentifier = "UIButton.Close"
        return button
    }()

    fileprivate lazy var backButton: UIButton = {
        let button = SheetNavigationButton(type: .custom)
        button.setImage(Image.icon_chevron_left_standalone.makeImage(template: true), for: .normal)
        button.tintColor = appearance.colors.icon
        button.accessibilityLabel = String.Localized.back
        button.accessibilityIdentifier = "UIButton.Back"
        return button
    }()

    lazy var additionalButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(appearance.colors.icon, for: .normal)
        button.setTitleColor(appearance.colors.icon.disabledColor, for: .disabled)
        button.titleLabel?.font = appearance.scaledFont(for: appearance.font.base.bold, style: .footnote, maximumPointSize: 20)

        return button
    }()

    let testModeView = TestModeView()
    let appearance: PaymentSheet.Appearance

    override var isUserInteractionEnabled: Bool {
        didSet {
            // Explicitly disable buttons to update their appearance
            closeButtonLeft.isEnabled = isUserInteractionEnabled
            closeButtonRight.isEnabled = isUserInteractionEnabled
            backButton.isEnabled = isUserInteractionEnabled
            additionalButton.isEnabled = isUserInteractionEnabled
        }
    }

    init(isTestMode: Bool, appearance: PaymentSheet.Appearance) {
        testModeView.isHidden = !isTestMode
        self.appearance = appearance
        super.init(frame: .zero)
        backgroundColor = appearance.colors.background.withAlphaComponent(0.9)
        [leftItemsStackView, closeButtonRight, additionalButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            leftItemsStackView.leadingAnchor.constraint(
                equalTo: leadingAnchor, constant: PaymentSheetUI.defaultPadding),
            leftItemsStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            leftItemsStackView.trailingAnchor.constraint(lessThanOrEqualTo: closeButtonRight.leadingAnchor),
            leftItemsStackView.trailingAnchor.constraint(lessThanOrEqualTo: additionalButton.leadingAnchor),

            additionalButton.trailingAnchor.constraint(
                equalTo: trailingAnchor, constant: -PaymentSheetUI.defaultPadding),
            additionalButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            closeButtonRight.trailingAnchor.constraint(
                equalTo: trailingAnchor, constant: -PaymentSheetUI.defaultPadding),
            closeButtonRight.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        closeButtonLeft.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
        closeButtonRight.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(didTapBackButton), for: .touchUpInside)

        setStyle(.close(showAdditionalButton: false))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: Self.height)
    }

    @objc
    private func didTapCloseButton() {
        STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: .paymentSheetDismissed)
        delegate?.sheetNavigationBarDidClose(self)
    }

    @objc
    private func didTapBackButton() {
        delegate?.sheetNavigationBarDidBack(self)
    }

    // MARK: -
    enum Style {
        case close(showAdditionalButton: Bool)
        case back
        case none
    }

    func setStyle(_ style: Style) {
        switch style {
        case .back:
            closeButtonLeft.isHidden = true
            closeButtonRight.isHidden = true
            additionalButton.isHidden = true
            backButton.isHidden = false
            bringSubviewToFront(backButton)
        case .close(let showAdditionalButton):
            closeButtonLeft.isHidden = !showAdditionalButton
            closeButtonRight.isHidden = showAdditionalButton
            additionalButton.isHidden = !showAdditionalButton
            if showAdditionalButton {
                bringSubviewToFront(additionalButton)
            }
            backButton.isHidden = true
        case .none:
            closeButtonLeft.isHidden = true
            closeButtonRight.isHidden = true
            additionalButton.isHidden = true
            backButton.isHidden = true
        }
    }

    func setShadowHidden(_ isHidden: Bool) {
        layer.shadowPath = CGPath(rect: bounds, transform: nil)
        layer.shadowOpacity = isHidden ? 0 : 0.1
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
    }
}
