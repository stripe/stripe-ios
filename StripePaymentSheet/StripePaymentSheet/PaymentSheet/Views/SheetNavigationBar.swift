//
//  SheetNavigationBar.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 10/19/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

protocol SheetNavigationBarDelegate: AnyObject {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar)
    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar)
}

/// For internal SDK use only
@objc(STP_Internal_SheetNavigationBar)
class SheetNavigationBar: UIView {
    static let height: CGFloat = 48
    weak var delegate: SheetNavigationBarDelegate?
    fileprivate lazy var closeButton: UIButton = {
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
            closeButton.isEnabled = isUserInteractionEnabled
            backButton.isEnabled = isUserInteractionEnabled
            additionalButton.isEnabled = isUserInteractionEnabled
        }
    }
    
    init(isTestMode: Bool, appearance: PaymentSheet.Appearance) {
        self.appearance = appearance
        super.init(frame: .zero)
        backgroundColor = appearance.colors.background.withAlphaComponent(0.9)
        [closeButton, backButton, additionalButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(
                equalTo: leadingAnchor, constant: PaymentSheetUI.defaultPadding),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            backButton.leadingAnchor.constraint(
                equalTo: leadingAnchor, constant: PaymentSheetUI.defaultPadding),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            additionalButton.trailingAnchor.constraint(
                equalTo: trailingAnchor, constant: -PaymentSheetUI.defaultPadding),
            additionalButton.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        
        if isTestMode {
            testModeView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(testModeView)
            
            NSLayoutConstraint.activate([
                testModeView.leadingAnchor.constraint(
                    equalTo: closeButton.trailingAnchor, constant: PaymentSheetUI.defaultPadding),
                testModeView.centerYAnchor.constraint(equalTo: centerYAnchor),
                testModeView.widthAnchor.constraint(equalToConstant: 82),
                testModeView.heightAnchor.constraint(equalToConstant: 23),
            ])
        }

        closeButton.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
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
            closeButton.isHidden = true
            additionalButton.isHidden = true
            backButton.isHidden = false
            bringSubviewToFront(backButton)
        case .close(let showAdditionalButton):
            closeButton.isHidden = false
            additionalButton.isHidden = !showAdditionalButton
            if showAdditionalButton {
                bringSubviewToFront(additionalButton)
            }
            backButton.isHidden = true
        case .none:
            closeButton.isHidden = true
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
