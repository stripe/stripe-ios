//
//  ConfirmButton.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 10/19/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

private let spinnerMoveToCenterAnimationDuration = 0.35
private let checkmarkStrokeDuration = 0.2

/// Buy or Continue button
class ConfirmButton: UIView {
    // MARK: Internal Properties
    enum Status {
        case enabled
        case disabled
        case processing
        case spinnerWithInteractionDisabled
        case succeeded
    }
    enum CallToActionType {
        case pay(amount: Int, currency: String, withLock: Bool = true)
        case add(paymentMethodType: PaymentSheet.PaymentMethodType)
        case `continue`
        case continueWithLock
        case setup
        case custom(title: String)
        case customWithLock(title: String)

        static func makeDefaultTypeForPaymentSheet(intent: Intent) -> CallToActionType {
            switch intent {
            case .paymentIntent(let paymentIntent):
                return .pay(amount: paymentIntent.amount, currency: paymentIntent.currency)
            case .setupIntent:
                return .setup
            case .deferredIntent(let intentConfig):
                switch intentConfig.mode {
                case .payment(let amount, let currency, _, _, _):
                    return .pay(amount: amount, currency: currency)
                case .setup:
                    return .setup
                }
            }
        }

        static func makeDefaultTypeForLink(intent: Intent) -> CallToActionType {
            switch intent {
            case .paymentIntent(let paymentIntent):
                return .pay(amount: paymentIntent.amount, currency: paymentIntent.currency, withLock: false)
            case .setupIntent:
                return .continue
            case .deferredIntent(let intentConfig):
                switch intentConfig.mode {
                case .payment(let amount, let currency, _, _, _):
                    return .pay(amount: amount, currency: currency, withLock: false)
                case .setup:
                    return .continue
                }
            }
        }
    }

    var font: UIFont? {
        get {
            return buyButton.font
        }
        set {
            buyButton.font = newValue
        }
    }

    private(set) var state: Status = .enabled
    private(set) var callToAction: CallToActionType

    // MARK: Private Properties
    private lazy var buyButton: BuyButton = {
        let buyButton = BuyButton(showProcessingLabel: showProcessingLabel, appearance: appearance)
        buyButton.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        return buyButton
    }()
    private let didTap: () -> Void
    private let didTapWhenDisabled: () -> Void
    private let appearance: PaymentSheet.Appearance
    private let showProcessingLabel: Bool

    // MARK: Init

    init(
        state: Status = .enabled,
        callToAction: CallToActionType,
        showProcessingLabel: Bool = true,
        appearance: PaymentSheet.Appearance = PaymentSheet.Appearance.default,
        didTap: @escaping () -> Void,
        didTapWhenDisabled: @escaping () -> Void = {}
    ) {
        self.state = state
        self.callToAction = callToAction
        self.showProcessingLabel = showProcessingLabel
        self.appearance = appearance
        self.didTap = didTap
        self.didTapWhenDisabled = didTapWhenDisabled
        super.init(frame: .zero)

        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        // primaryButton.backgroundColor takes priority over appearance.colors.primary
        tintColor = appearance.primaryButton.backgroundColor ?? appearance.colors.primary
        layer.applyShadow(shadow: appearance.primaryButton.shadow?.asElementThemeShadow ?? appearance.shadow.asElementThemeShadow)
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
        font = appearance.primaryButton.font ?? appearance.scaledFont(for: appearance.font.base.medium, style: .callout, maximumPointSize: 25)
        buyButton.titleLabel.sizeToFit()
        addAndPinSubview(buyButton)

        applyCornerRadius()
        update()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didBecomeActive),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

#if !os(visionOS)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.buyButton.update(status: state, callToAction: callToAction, animated: false)
    }
#endif

    @objc private func didBecomeActive() {
        self.buyButton.update(status: self.state, callToAction: self.callToAction, animated: false)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Internal Methods

    func update(
        state: Status? = nil,
        callToAction: CallToActionType? = nil,
        animated: Bool = false,
        completion: (() -> Void)? = nil
    ) {
        update(
            state: state ?? self.state,
            callToAction: callToAction ?? self.callToAction,
            animated: animated,
            completion: completion)
    }

    func update(
        state: Status,
        callToAction: CallToActionType,
        animated: Bool = false,
        completion: (() -> Void)? = nil
    ) {
        self.state = state
        self.callToAction = callToAction

        // Enable/disable
        isUserInteractionEnabled = (state == .enabled || state == .disabled)

        // Update the buy button; it has its own presentation logic
        self.buyButton.update(status: state, callToAction: callToAction, animated: animated)

        if let completion = completion {
            let delay: TimeInterval = {
                guard animated else {
                    return 0
                }

                return state == .succeeded
                ? PaymentSheetUI.delayBetweenSuccessAndDismissal
                : PaymentSheetUI.defaultAnimationDuration
            }()

            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: completion)
        }
    }

    // MARK: - Private Methods

    @objc
    private func handleTap() {
        if case .enabled = state {
            didTap()
        } else if case .disabled = state {
            // When the disabled button is tapped, trigger validation error display
            didTapWhenDisabled()
            // Resign first responder (as we would if the button was disabled)
            superview?.endEditing(true)
        }
    }

    private func applyCornerRadius() {
        if let cornerRadius = appearance.primaryButton.cornerRadius {
            // Use primary button corner radius
            buyButton.layer.cornerRadius = cornerRadius
        } else {
            buyButton.applyCornerRadiusOrConfiguration(for: appearance, ios26DefaultCornerStyle: .capsule)
        }
    }

    // MARK: - BuyButton

    class BuyButton: UIControl {
        var font: UIFont? {
            didSet {
                titleLabel.font = font
            }
        }

        /// Background color for the `.disabled` state.
        var disabledBackgroundColor: UIColor {
            return appearance.primaryButton.disabledBackgroundColor ?? appearance.primaryButton.backgroundColor ?? appearance.colors.primary
        }

        /// Background color for the `.succeeded` state.
        var succeededBackgroundColor: UIColor {
            return appearance.primaryButton.successBackgroundColor
        }

        private var status: Status = .enabled
        private let appearance: PaymentSheet.Appearance
        private let showProcessingLabel: Bool

        override var intrinsicContentSize: CGSize {
            return CGSize(
                width: UIView.noIntrinsicMetric,
                height: appearance.primaryButton.height
            )
        }

        lazy var highlightDimView: UIView = {
            let view = UIView()
            view.backgroundColor = UIColor.black.withAlphaComponent(0.18)
            return view
        }()
        override var isHighlighted: Bool {
            didSet {
                highlightDimView.frame = bounds
                if self.isHighlighted {
                    UIView.animate(
                        withDuration: PaymentSheetUI.defaultAnimationDuration, delay: 0.2,
                        options: [.beginFromCurrentState],
                        animations: {
                            self.highlightDimView.alpha = 1
                        }, completion: nil)
                } else {
                    UIView.animate(
                        withDuration: PaymentSheetUI.quickAnimationDuration, delay: 0,
                        options: [.beginFromCurrentState],
                        animations: {
                            self.highlightDimView.alpha = 0
                        }, completion: nil)
                }
            }
        }
        lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.textAlignment = .center
            label.font = .preferredFont(forTextStyle: .callout, weight: .medium, maximumPointSize: 25)
            label.textColor = .white
            label.adjustsFontForContentSizeCategory = true
            return label
        }()
        lazy var lockIcon: UIImageView = {
            let image = Image.icon_lock.makeImage(template: true)
            let icon = UIImageView(image: image)
            icon.setContentCompressionResistancePriority(.required, for: .horizontal)
            return icon
        }()
        lazy var spinnerCenteredToLockConstraint: NSLayoutConstraint = {
            return spinner.centerXAnchor.constraint(equalTo: lockIcon.centerXAnchor, constant: -4)
        }()
        lazy var spinnerCenteredConstraint: NSLayoutConstraint = {
            return spinner.centerXAnchor.constraint(equalTo: centerXAnchor)
        }()
        let spinnerSize = CGSize(width: 20, height: 20)
        lazy var spinner: CheckProgressView = {
            return CheckProgressView(frame: CGRect(origin: .zero, size: spinnerSize.applying(CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))))
        }()
        lazy var addIcon: UIImageView = {
            let image = Image.icon_plus.makeImage(template: true)
            let icon = UIImageView(image: image)
            icon.setContentCompressionResistancePriority(.required, for: .horizontal)
            return icon
        }()
        var scaleFactor: CGFloat {
            guard let primaryButtonFont = appearance.primaryButton.font else {
                return appearance.font.sizeScaleFactor
            }
            // scale by primary button text, not the overall
            return primaryButtonFont.pointSize/UIFont.labelFontSize
        }
        var foregroundColor: UIColor = .white {
            didSet {
                foregroundColorDidChange()
            }
        }

        var overriddenForegroundColor: UIColor?

        init(
            showProcessingLabel: Bool = true,
            appearance: PaymentSheet.Appearance = .default
        ) {
            self.showProcessingLabel = showProcessingLabel
            self.appearance = appearance
            super.init(frame: .zero)
            preservesSuperviewLayoutMargins = true
            layer.masksToBounds = true
            layer.borderWidth = appearance.primaryButton.borderWidth

            isAccessibilityElement = true

            // Add views
            let views = ["titleLabel": titleLabel, "lockIcon": lockIcon, "spinnyView": spinner, "addIcon": addIcon]
            views.values.forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
                addSubview($0)
            }
            // Add a dark view on top
            addSubview(highlightDimView)
            highlightDimView.alpha = 0

            let titleLabelCenterXConstraint = titleLabel.centerXAnchor.constraint(
                equalTo: centerXAnchor)
            titleLabelCenterXConstraint.priority = .defaultLow
            NSLayoutConstraint.activate([
                // Add icon
                addIcon.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                addIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
                addIcon.widthAnchor.constraint(equalToConstant: addIcon.intrinsicContentSize.width.scaled(by: scaleFactor)),
                addIcon.heightAnchor.constraint(equalToConstant: addIcon.intrinsicContentSize.height.scaled(by: scaleFactor)),

                // Label
                titleLabelCenterXConstraint,
                titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
                titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor),

                // Lock icon
                lockIcon.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),
                lockIcon.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                lockIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
                lockIcon.widthAnchor.constraint(equalToConstant: lockIcon.intrinsicContentSize.width.scaled(by: scaleFactor)),
                lockIcon.heightAnchor.constraint(equalToConstant: lockIcon.intrinsicContentSize.height.scaled(by: scaleFactor)),

                // Spinner
                spinnerCenteredToLockConstraint,
                spinner.centerYAnchor.constraint(equalTo: lockIcon.centerYAnchor),
                spinner.widthAnchor.constraint(equalToConstant: spinnerSize.width.scaled(by: scaleFactor)),
                spinner.heightAnchor.constraint(equalToConstant: spinnerSize.height.scaled(by: scaleFactor)),
            ])
            layer.borderColor = appearance.primaryButton.borderColor.cgColor
            overriddenForegroundColor = appearance.primaryButton.textColor
        }

#if !os(visionOS)
        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            layer.borderColor = appearance.primaryButton.borderColor.cgColor
        }
#endif

        override func tintColorDidChange() {
            super.tintColorDidChange()
            updateColors()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func update(status: Status, callToAction: CallToActionType, animated: Bool) {
            self.status = status

            // Update the label with a crossfade UIView.transition; UIView.animate doesn't provide an animation for text changes
            let text: String? = {
                switch status {
                case .enabled, .disabled, .spinnerWithInteractionDisabled:
                    switch callToAction {
                    case .add(let paymentMethodType):
                        if paymentMethodType == .instantDebits {
                            return STPLocalizedString("Add bank account", "Button prompt to add a bank account as a payment method.")
                        } else {
                            return String.Localized.continue
                        }
                    case .continue, .continueWithLock:
                        return String.Localized.continue
                    case let .pay(amount, currency, _):
                        let localizedAmount = String.localizedAmountDisplayString(
                            for: amount, currency: currency)
                        let localized = STPLocalizedString(
                            "Pay %@",
                            "Label of a button that initiates payment when tapped"
                        )
                        return String(format: localized, localizedAmount)
                    case .setup:
                        return STPLocalizedString(
                            "Set up",
                            "Label of a button displayed below a payment method form. Tapping the button sets the payment method up for future use"
                        )
                    case let .custom(title):
                        return title
                    case let .customWithLock(title):
                        return title
                    }
                case .processing:
                    return showProcessingLabel ? STPLocalizedString(
                        "Processing...",
                        "Label of a button that, when tapped, initiates payment, becomes disabled, and displays this text"
                    ) : nil
                case .succeeded:
                    return nil
                }
            }()

            // Show/hide lock and add icons
            switch callToAction {
            case .add(let paymentMethodType):
                lockIcon.isHidden = true
                addIcon.isHidden = paymentMethodType != .instantDebits
            case .custom, .continue:
                lockIcon.isHidden = true
                addIcon.isHidden = true
            case .customWithLock, .continueWithLock:
                lockIcon.isHidden = false
                addIcon.isHidden = true
            case .pay(_, _, let withLock):
                lockIcon.isHidden = !withLock
                addIcon.isHidden = true
            case .setup:
                lockIcon.isHidden = false
                addIcon.isHidden = true
            }

            // Update accessibility information
            accessibilityLabel = text
            accessibilityTraits = (status == .enabled) ? [.button] : [.button, .notEnabled]

            let animationDuration = animated ? PaymentSheetUI.defaultAnimationDuration : 0

            if text != nil {
                UIView.transition(
                    with: titleLabel,
                    duration: animationDuration,
                    options: .transitionCrossDissolve
                ) {
                    // UILabel's documentation states that setting the text will override an existing attributedText, but that isn't true. We need to reset it manually.
                    self.titleLabel.attributedText = nil
                    self.titleLabel.text = text

                    // If differentiate without color is enabled, we should underline the button instead.
                    if UIAccessibility.shouldDifferentiateWithoutColor && status == .enabled,
                       let font = self.titleLabel.font,
                       let foregroundColor = self.titleLabel.textColor,
                       let text = text
                    {
                        let attributes: [NSAttributedString.Key: Any] = [
                            .font: font,
                            .foregroundColor: foregroundColor,
                            .underlineStyle: NSUnderlineStyle.single.rawValue,
                        ]
                        self.titleLabel.attributedText = NSAttributedString(
                            string: text, attributes: attributes)
                    }
                }
            } else {
                UIView.animate(withDuration: animationDuration) {
                    self.titleLabel.text = text
                    self.titleLabel.alpha = 0
                }
            }

            // Animate everything else with the usual UIView.animate
            UIView.animate(withDuration: animationDuration) {
                self.titleLabel.alpha = {
                    switch status {
                    case .disabled:
                        return self.appearance.primaryButton.disabledTextColor == nil ? 0.6 : 1.0
                    case .spinnerWithInteractionDisabled:
                        return 0.6
                    case .succeeded:
                        return 0
                    default:
                        return 1.0
                    }
                }()

                self.updateColors()

                // Show/hide the lock icon, spinner
                switch status {
                case .disabled, .enabled:
                    self.lockIcon.alpha = self.titleLabel.alpha
                    self.addIcon.alpha = self.titleLabel.alpha
                    self.spinner.alpha = 0
                case .processing, .spinnerWithInteractionDisabled:
                    self.lockIcon.alpha = 0
                    self.addIcon.alpha = 0
                    self.spinner.alpha = 1
                    self.spinnerCenteredToLockConstraint.isActive = self.showProcessingLabel
                    self.spinnerCenteredConstraint.isActive = !self.showProcessingLabel
                    self.spinner.beginProgress()
                case .succeeded:
                    // Assumes this is only true once in ConfirmButton's lifetime
                    self.animateSuccess()
                }
            }
        }

        private func animateSuccess() {
            // Animate the spinner to the middle
            spinnerCenteredToLockConstraint.isActive = false
            spinnerCenteredConstraint.isActive = true
            setNeedsLayout()
            UIView.animate(
                withDuration: spinnerMoveToCenterAnimationDuration, delay: 0, options: .curveEaseOut
            ) {
                self.layoutIfNeeded()
            } completion: { (_) in
            }
            // Complete the circle and draw a checkmark
            self.spinner.completeProgress()

        }

        private func backgroundColor(for status: Status) -> UIColor {
            switch status {
            case .enabled, .processing, .spinnerWithInteractionDisabled:
                return tintColor
            case .disabled:
                return disabledBackgroundColor
            case .succeeded:
                return succeededBackgroundColor
            }
        }

        private func foregroundColor(for status: Status) -> UIColor {
            let background = backgroundColor(for: status)

            // Use disabledTextColor if in disabled state and provided, otherwise fallback to foreground color
            if status == .disabled, let disabledTextColor = appearance.primaryButton.disabledTextColor {
                return disabledTextColor
            }

            // Use successTextColor if in succeeded state and provided, otherwise fallback to foreground color
            if status == .succeeded, let successTextColor = appearance.primaryButton.successTextColor {
                return successTextColor
            }

            // if foreground is set prefer that over a dynamic contrasting color in all other states
            return overriddenForegroundColor ?? background.contrastingColor
        }

        private func updateColors() {
            self.backgroundColor = self.backgroundColor(for: status)
            self.foregroundColor = self.foregroundColor(for: status)
        }

        private func foregroundColorDidChange() {
            titleLabel.textColor = foregroundColor
            lockIcon.tintColor = foregroundColor
            spinner.color = foregroundColor
        }
    }

    // MARK: - CheckProgressView

    class CheckProgressView: UIView {
        let circleLayer = CAShapeLayer()
        let checkmarkLayer = CAShapeLayer()
        let baseLineWidth: CGFloat
        var color: UIColor = .white {
            didSet {
                colorDidChange()
            }
        }

        init(frame: CGRect, baseLineWidth: CGFloat = 1.0) {
            self.baseLineWidth = baseLineWidth
            // Circle
            let circlePath = UIBezierPath(
                arcCenter: CGPoint(
                    x: frame.size.width / 2,
                    y: frame.size.height / 2),
                radius: (frame.size.width) / 2,
                startAngle: 0.0,
                endAngle: CGFloat.pi * 2,
                clockwise: false)
            circleLayer.bounds = CGRect(
                x: 0, y: 0, width: frame.size.width, height: frame.size.width)
            circleLayer.path = circlePath.cgPath
            circleLayer.fillColor = UIColor.clear.cgColor
            circleLayer.lineCap = .round
            circleLayer.lineWidth = baseLineWidth
            circleLayer.strokeEnd = 0.0

            // Checkmark
            let checkmarkPath = UIBezierPath()
            let checkOrigin = CGPoint(x: frame.size.width * 0.33, y: frame.size.height * 0.5)
            let checkPoint1 = CGPoint(x: frame.size.width * 0.46, y: frame.size.height * 0.635)
            let checkPoint2 = CGPoint(x: frame.size.width * 0.70, y: frame.size.height * 0.36)
            checkmarkPath.move(to: checkOrigin)
            checkmarkPath.addLine(to: checkPoint1)
            checkmarkPath.addLine(to: checkPoint2)

            checkmarkLayer.bounds = CGRect(
                x: 0, y: 0, width: frame.size.width, height: frame.size.width)
            checkmarkLayer.path = checkmarkPath.cgPath
            checkmarkLayer.lineCap = .round
            checkmarkLayer.fillColor = UIColor.clear.cgColor
            checkmarkLayer.lineWidth = baseLineWidth + 0.5
            checkmarkLayer.strokeEnd = 0.0

            checkmarkLayer.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
            circleLayer.position = CGPoint(x: frame.width / 2, y: frame.height / 2)

            super.init(frame: frame)

            self.backgroundColor = UIColor.clear
            layer.addSublayer(circleLayer)
            layer.addSublayer(checkmarkLayer)

            colorDidChange()
        }

        required init?(coder: NSCoder) {
            fatalError()
        }

        func beginProgress() {
            checkmarkLayer.strokeEnd = 0.0  // Make sure checkmark is not drawn yet
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.duration = 1.0
            animation.fromValue = 0
            animation.toValue = 0.8
            animation.timingFunction = CAMediaTimingFunction(
                name: CAMediaTimingFunctionName.easeOut)
            circleLayer.strokeEnd = 0.8
            circleLayer.add(animation, forKey: "animateCircle")
            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
            rotationAnimation.byValue = 2.0 * Float.pi
            rotationAnimation.duration = 1
            rotationAnimation.repeatCount = .infinity
            circleLayer.add(rotationAnimation, forKey: "animateRotate")
        }

        func completeProgress(completion: (() -> Void)? = nil) {
            CATransaction.begin()
            // Note: Make sure the completion block is set before adding any animations
            CATransaction.setCompletionBlock {
                if let completion {
                    completion()
                }
            }
            circleLayer.removeAnimation(forKey: "animateCircle")

            // Close the circle
            let circleAnimation = CABasicAnimation(keyPath: "strokeEnd")
            circleAnimation.duration = spinnerMoveToCenterAnimationDuration
            circleAnimation.fromValue = 0.8
            circleAnimation.toValue = 1
            circleAnimation.timingFunction = CAMediaTimingFunction(
                name: CAMediaTimingFunctionName.easeIn)
            circleLayer.strokeEnd = 1.0
            circleLayer.add(circleAnimation, forKey: "animateDone")

            // Check the mark
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.beginTime = CACurrentMediaTime() + circleAnimation.duration + 0.15  // Start after the circle closes
            animation.fillMode = .backwards
            animation.duration = checkmarkStrokeDuration
            animation.fromValue = 0.0
            animation.toValue = 1
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
            checkmarkLayer.strokeEnd = 1.0
            checkmarkLayer.add(animation, forKey: "animateFinishCircle")
            CATransaction.commit()
        }

        private func colorDidChange() {
            circleLayer.strokeColor = color.cgColor
            checkmarkLayer.strokeColor = color.cgColor
        }
    }
}
