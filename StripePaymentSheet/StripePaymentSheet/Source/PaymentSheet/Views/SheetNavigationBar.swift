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
    static let height: CGFloat = LiquidGlassDetector.isEnabled ? 64 : 52
    weak var delegate: SheetNavigationBarDelegate?
    fileprivate lazy var leftItemsStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [dummyView, closeButtonLeft, backButton, testModeView])
        stack.spacing = PaymentSheetUI.defaultPadding
        stack.setCustomSpacing(PaymentSheetUI.navBarPadding, after: dummyView)
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

    // Custom gradient blur view for liquid glass effect
    private lazy var gradientBlurView: GradientBlurEffectView = {
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let backgroundColor = appearance.colors.background

        // Create gradient mask: white = visible, clear = hidden
        let gradientColors: [CGColor] = [
            UIColor.white.withAlphaComponent(0.6).cgColor,
            UIColor.white.withAlphaComponent(0.55).cgColor,
            UIColor.white.withAlphaComponent(0.50).cgColor,
            UIColor.white.withAlphaComponent(0.45).cgColor,
            UIColor.white.withAlphaComponent(0.40).cgColor,
            UIColor.white.withAlphaComponent(0.35).cgColor,
            UIColor.white.withAlphaComponent(0.30).cgColor,
            UIColor.white.withAlphaComponent(0.25).cgColor,
            UIColor.white.withAlphaComponent(0.20).cgColor,
            UIColor.white.withAlphaComponent(0.15).cgColor,
            UIColor.white.withAlphaComponent(0.05).cgColor,  // 0.05: Basically not visible
        ]

        let gradientView = GradientBlurEffectView(
            effect: blurEffect,
            colors: gradientColors,
            locations: [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0],
            startPoint: CGPoint(x: 0, y: 0),  // Top
            endPoint: CGPoint(x: 0, y: 1)     // Bottom
        )
        gradientView.alpha = 1.0  // Always visible - gradient itself handles the fade
        return gradientView
    }()

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

        #if !os(visionOS)
        // Add gradient blur view as background
        if LiquidGlassDetector.isEnabled {
            gradientBlurView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(gradientBlurView)
            NSLayoutConstraint.activate([
                // Gradient blur view constraints
                gradientBlurView.leadingAnchor.constraint(equalTo: leadingAnchor),
                gradientBlurView.trailingAnchor.constraint(equalTo: trailingAnchor),
                gradientBlurView.topAnchor.constraint(equalTo: topAnchor),
                gradientBlurView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        } else {
            backgroundColor = appearance.colors.background.withAlphaComponent(0.9)
        }
        #endif

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
                equalTo: trailingAnchor, constant: -PaymentSheetUI.navBarPadding),
            additionalButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            closeButtonRight.trailingAnchor.constraint(
                equalTo: trailingAnchor, constant: -PaymentSheetUI.navBarPadding),
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
        if !LiquidGlassDetector.isEnabled {
            layer.shadowPath = CGPath(rect: bounds, transform: nil)
            layer.shadowOpacity = isHidden ? 0 : 0.1
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 2)
        }
    }

    func createBackButton() -> UIButton {
        let button = SheetNavigationButton(type: .custom)
        button.setImage(Image.icon_chevron_left_standalone.makeImage(template: true), for: .normal)
        button.tintColor = appearance.colors.icon
        button.accessibilityLabel = String.Localized.back
        button.accessibilityIdentifier = "UIButton.Back"
        #if compiler(>=6.2)
        if #available(iOS 26.0, *),
           LiquidGlassDetector.isEnabled {
            button.configuration = .glass()
        }
        #endif
        return button
    }

    func createCloseButton() -> UIButton {
        let button = SheetNavigationButton(type: .custom)
        button.setImage(Image.icon_x_standalone.makeImage(template: true), for: .normal)
        button.tintColor = appearance.colors.icon
        button.accessibilityLabel = String.Localized.close
        button.accessibilityIdentifier = "UIButton.Close"
        #if compiler(>=6.2)
        if #available(iOS 26.0, *),
           LiquidGlassDetector.isEnabled{
            button.configuration = .glass()
        }
        #endif
        return button
    }
}

/// Custom view that combines UIBlurEffect with a gradient mask for liquid glass effect
class GradientBlurEffectView: UIVisualEffectView {
    private let gradientLayer = CAGradientLayer()

    init(effect: UIBlurEffect, colors: [CGColor], locations: [NSNumber], startPoint: CGPoint, endPoint: CGPoint) {
        super.init(effect: effect)

        // Configure the gradient layer as a mask
        gradientLayer.colors = colors
        gradientLayer.locations = locations
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint

        // Use the gradient as a mask on the entire view instead of adding as sublayer
        self.layer.mask = gradientLayer
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = self.bounds
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
        #if compiler(>=6.2)
        if #available(iOS 26.0, *),
           LiquidGlassDetector.isEnabled {
            configuration = .glass()
        }
        #endif
    }
}
