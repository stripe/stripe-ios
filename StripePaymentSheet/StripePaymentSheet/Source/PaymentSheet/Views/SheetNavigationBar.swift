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
    static func height(appearance: PaymentSheet.Appearance) -> CGFloat {
        return appearance.navigationBarStyle.isGlass ? 76 : 52

    }
    weak var delegate: SheetNavigationBarDelegate?
    fileprivate lazy var leftItemsStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [dummyView, closeButtonLeft, backButton, testModeView])
        stack.spacing = PaymentSheetUI.defaultPadding
        stack.setCustomSpacing(PaymentSheetUI.navBarPadding(appearance: appearance), after: dummyView)
        stack.alignment = .center
        return stack
    }()
    // Used for allowing larger tap area to the left of closeButtonLeft
    fileprivate lazy var dummyView: UIView = {
        let dummyView = UIView(frame: .zero)
        return dummyView
    }()
    internal lazy var closeButtonLeft: UIButton = {
        createCloseButton()
    }()

    internal lazy var closeButtonRight: UIButton = {
        createCloseButton()
    }()

    fileprivate lazy var backButton: UIButton = {
        createBackButton()
    }()

    lazy var additionalButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(appearance.colors.primary, for: .normal)
        button.setTitleColor(appearance.colors.primary.disabledColor, for: .disabled)
        button.titleLabel?.font = appearance.scaledFont(for: appearance.font.base.bold, style: .footnote, maximumPointSize: 20)

        return button
    }()

    var leftmostElement: UIView {
        leftItemsStackView
    }

    var rightmostElement: UIView? {
        if !closeButtonRight.isHidden {
            return closeButtonRight
        } else if !additionalButton.isHidden {
            return additionalButton
        }
        return nil
    }

    let testModeView = TestModeView()
    let appearance: PaymentSheet.Appearance
    let shouldLogPaymentSheetAnalyticsOnDismissal: Bool

    override var isUserInteractionEnabled: Bool {
        didSet {
            // Explicitly disable buttons to update their appearance
            closeButtonLeft.isEnabled = isUserInteractionEnabled
            closeButtonRight.isEnabled = isUserInteractionEnabled
            backButton.isEnabled = isUserInteractionEnabled
            additionalButton.isEnabled = isUserInteractionEnabled
        }
    }

    init(isTestMode: Bool, appearance: PaymentSheet.Appearance, shouldLogPaymentSheetAnalyticsOnDismissal: Bool = true) {
        testModeView.isHidden = !isTestMode
        self.appearance = appearance
        self.shouldLogPaymentSheetAnalyticsOnDismissal = shouldLogPaymentSheetAnalyticsOnDismissal
        super.init(frame: .zero)

        if appearance.navigationBarStyle.isPlain {
            backgroundColor = appearance.colors.background.withAlphaComponent(0.9)
        }

        [leftItemsStackView, closeButtonRight, additionalButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            leftItemsStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            leftItemsStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            leftItemsStackView.trailingAnchor.constraint(lessThanOrEqualTo: closeButtonRight.leadingAnchor),
            leftItemsStackView.trailingAnchor.constraint(lessThanOrEqualTo: additionalButton.leadingAnchor),
            leftItemsStackView.heightAnchor.constraint(equalTo: heightAnchor),

            additionalButton.trailingAnchor.constraint(
                equalTo: trailingAnchor, constant: -PaymentSheetUI.navBarPadding(appearance: appearance)),
            additionalButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            closeButtonRight.trailingAnchor.constraint(
                equalTo: trailingAnchor, constant: -PaymentSheetUI.navBarPadding(appearance: appearance)),
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
        return CGSize(width: UIView.noIntrinsicMetric, height: Self.height(appearance: appearance))
    }

    @objc
    private func didTapCloseButton() {
        if shouldLogPaymentSheetAnalyticsOnDismissal {
            STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: .paymentSheetDismissed)
        }
        delegate?.sheetNavigationBarDidClose(self)
    }

    @objc
    private func didTapBackButton() {
        delegate?.sheetNavigationBarDidBack(self)
    }

    // MARK: -
    enum Style {
        case close(showAdditionalButton: Bool)
        case back(showAdditionalButton: Bool)
        case none
    }

    func setStyle(_ style: Style) {
        switch style {
        case .back(let showAdditionalButton):
            closeButtonLeft.isHidden = true
            closeButtonRight.isHidden = true
            additionalButton.isHidden = !showAdditionalButton
            if showAdditionalButton {
                bringSubviewToFront(additionalButton)
            }
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
        if appearance.navigationBarStyle.isPlain {
            layer.shadowPath = CGPath(rect: bounds, transform: nil)
            layer.shadowOpacity = isHidden ? 0 : 0.1
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 2)
        }
    }
    func createBackButton() -> UIButton {
        return appearance.navigationBarStyle.isGlass ? createGlassBackButton() : createPlainBackButton()
    }
    func createPlainBackButton() -> UIButton {
        let button = SheetNavigationButton(type: .custom)
        let image = Image.icon_chevron_left_standalone.makeImage(template: true)
        button.setImage(image, for: .normal)
        button.tintColor = appearance.colors.icon
        button.accessibilityLabel = String.Localized.back
        button.accessibilityIdentifier = "UIButton.Back"
        return button
    }
    func createGlassBackButton() -> UIButton {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        button.widthAnchor.constraint(equalToConstant: 44).isActive = true
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        let image = UIImage(systemName: "chevron.left", withConfiguration: config)

        button.setImage(image, for: .normal)
        button.tintColor = appearance.colors.icon

        button.accessibilityLabel = String.Localized.back
        button.accessibilityIdentifier = "UIButton.Back"
        button.ios26_applyGlassConfiguration()

        return button
    }

    func createCloseButton() -> UIButton {
        return appearance.navigationBarStyle.isGlass ? createGlassCloseButton() : createPlainCloseButton()
    }
    func createPlainCloseButton() -> UIButton {
        let button = SheetNavigationButton(type: .custom)
        let image = Image.icon_x_standalone.makeImage(template: true)
        button.setImage(image, for: .normal)
        button.tintColor = appearance.colors.icon

        button.accessibilityLabel = String.Localized.close
        button.accessibilityIdentifier = "UIButton.Close"

        return button
    }
    func createGlassCloseButton() -> UIButton {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        button.widthAnchor.constraint(equalToConstant: 44).isActive = true
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        let image = UIImage(systemName: "xmark", withConfiguration: config)

        button.setImage(image, for: .normal)
        button.tintColor = appearance.colors.icon

        button.accessibilityLabel = String.Localized.close
        button.accessibilityIdentifier = "UIButton.Close"
        button.ios26_applyGlassConfiguration()

        return button
    }
}

extension UIButton {
    func configureCommonEditButton(isEditingPaymentMethods: Bool, appearance: PaymentSheet.Appearance) {
        let title = isEditingPaymentMethods ? UIButton.doneButtonTitle : UIButton.editButtonTitle
        setTitle(title, for: .normal)
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.textAlignment = .right
        titleLabel?.font = appearance.scaledFont(for: appearance.font.base.medium, size: 14, maximumPointSize: 22)
        accessibilityIdentifier = "edit_saved_button"
        if appearance.navigationBarStyle.isGlass {
            ios26_applyGlassConfiguration()
        }
    }
}
