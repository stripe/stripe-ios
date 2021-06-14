//
//  ConfirmButton.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 10/19/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
import UIKit

private let spinnerMoveToCenterAnimationDuration = 0.35
private let checkmarkStrokeDuration = 0.2

/// Buy button or Apple Pay
class ConfirmButton: UIView {
    static let shadowOpacity: Float = 0.05
    // MARK: Internal Properties
    enum Status {
        case enabled
        case disabled
        case processing
        case succeeded
    }
    enum Style {
        case stripe
        case applePay
    }
    enum CallToActionType {
        case pay(amount: Int, currency: String)
        case add(paymentMethodType: STPPaymentMethodType)
        case setup
        // TODO: Add custom cta type
    }
    private(set) var state: Status = .enabled
    private(set) var style: Style
    private(set) var callToAction: CallToActionType

    // MARK: Private Properties
    private lazy var buyButton: BuyButton = {
        let buyButton = BuyButton()
        buyButton.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        return buyButton
    }()
    private lazy var applePayButton: PKPaymentButton = {
        let button = PKPaymentButton(
            paymentButtonType: .plain, paymentButtonStyle: .compatibleAutomatic)
        button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        return button
    }()
    private let didTap: () -> Void

    // MARK: Init

    init(style: Style, callToAction: CallToActionType, didTap: @escaping () -> Void) {
        self.didTap = didTap
        self.style = style
        self.callToAction = callToAction
        super.init(frame: .zero)

        // Shadows
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = 4
        layer.shadowOpacity = Self.shadowOpacity

        // Add views
        let views = ["applePayButton": applePayButton, "buyButton": buyButton]
        views.values.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(
                withVisualFormat: "H:|[buyButton]|", options: [], metrics: nil, views: views)
                + NSLayoutConstraint.constraints(
                    withVisualFormat: "V:|[buyButton(44)]|", options: [], metrics: nil, views: views
                )
                + NSLayoutConstraint.constraints(
                    withVisualFormat: "H:|[applePayButton]|", options: [], metrics: nil,
                    views: views)
                + NSLayoutConstraint.constraints(
                    withVisualFormat: "V:|[applePayButton]|", options: [], metrics: nil,
                    views: views)
        )

        update()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        update()  // update after moving to window to pick up tintColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath  // To improve performance
    }

    // MARK: - Internal Methods

    func update(
        state: Status? = nil,
        style: Style? = nil,
        callToAction: CallToActionType? = nil,
        animated: Bool = false,
        completion: (() -> Void)? = nil
    ) {
        update(
            state: state ?? self.state,
            style: style ?? self.style,
            callToAction: callToAction ?? self.callToAction,
            animated: animated,
            completion: completion)
    }

    func update(
        state: Status,
        style: Style,
        callToAction: CallToActionType,
        animated: Bool = false,
        completion: (() -> Void)? = nil
    ) {
        self.state = state
        self.style = style
        self.callToAction = callToAction

        UIView.animate(withDuration: animated ? PaymentSheetUI.defaultAnimationDuration : 0) {
            // Show one style or the other
            if style == .applePay {
                self.buyButton.alpha = 0
                self.applePayButton.alpha = 1
            } else {
                self.buyButton.alpha = 1
                self.applePayButton.alpha = 0
            }
        }

        // Enable/disable
        isUserInteractionEnabled = state == .enabled

        // Update the buy button; it has its own presentation logic
        self.buyButton.update(status: state, callToAction: callToAction)
    }

    // MARK: - Private Methods

    @objc
    private func handleTap() {
        if case .enabled = state {
            didTap()
        }
    }

    // MARK: - BuyButton

    class BuyButton: UIControl {
        let hairlineBorderColor: UIColor = CompatibleColor.quaternaryLabel
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
            label.font = .preferredFont(forTextStyle: .callout)
            label.textColor = .white
            return label
        }()
        lazy var lockIcon: UIImageView = {
            let image = Image.icon_lock.makeImage(template: true)
            let icon = UIImageView(image: image)
            icon.setContentCompressionResistancePriority(.required, for: .horizontal)
            icon.tintColor = titleLabel.textColor
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
            return CheckProgressView(frame: CGRect(origin: .zero, size: spinnerSize))
        }()

        init() {
            super.init(frame: .zero)
            layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            layer.cornerRadius = PaymentSheetUI.defaultButtonCornerRadius
            layer.masksToBounds = true
            // Give it a subtle outline, to safeguard against user provided colors that don't contrast enough with the background
            layer.borderWidth = 1

            isAccessibilityElement = true

            // Add views
            let views = ["titleLabel": titleLabel, "lockIcon": lockIcon, "spinnyView": spinner]
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
            NSLayoutConstraint.activate(
                NSLayoutConstraint.constraints(
                    withVisualFormat: "H:|-(>=0)-[titleLabel]-(>=8)-[lockIcon]-|", options: [],
                    metrics: nil, views: views)
                    + NSLayoutConstraint.constraints(
                        withVisualFormat: "V:|-[titleLabel]-|", options: [], metrics: nil,
                        views: views) + [
                        titleLabelCenterXConstraint,
                        lockIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
                        spinnerCenteredToLockConstraint,
                        spinner.centerYAnchor.constraint(equalTo: lockIcon.centerYAnchor),
                        spinner.widthAnchor.constraint(equalToConstant: spinnerSize.width),
                        spinner.heightAnchor.constraint(equalToConstant: spinnerSize.height),
                    ]
            )
            layer.borderColor = CompatibleColor.quaternaryLabel.cgColor
        }

        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            layer.borderColor = hairlineBorderColor.cgColor
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func update(status: Status, callToAction: CallToActionType) {
            // Update the label with a crossfade UIView.transition; UIView.animate doesn't provide an animation for text changes
            let text: String? = {
                switch status {
                case .enabled, .disabled:
                    switch callToAction {
                    case let .add(paymentMethodType):
                        switch paymentMethodType {
                        case .card:
                            return STPLocalizedString(
                                "Add card",
                                "Label of a button displayed below a card entry form that saves the card details"
                            )
                        default:
                            return STPLocalizedString(
                                "Select",
                                "Label of a button displayed below a payment method form. Tapping the button closes the form and uses the entered payment method details for checkout in the next step"
                            )
                        }
                    case let .pay(amount, currency):
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
                    }
                case .processing:
                    return STPLocalizedString(
                        "Processing...",
                        "Label of a button that, when tapped, initiates payment, becomes disabled, and displays this text"
                    )
                case .succeeded:
                    return nil
                }
            }()

            // Update accessibility information
            accessibilityLabel = text
            accessibilityTraits = (status == .enabled) ? [.button] : [.button, .notEnabled]

            if text != nil {
                UIView.transition(
                    with: titleLabel, duration: PaymentSheetUI.defaultAnimationDuration,
                    options: .transitionCrossDissolve
                ) {
                    // UILabel's documentation states that setting the text will override an existing attributedText, but that isn't true. We need to reset it manually.
                    self.titleLabel.attributedText = nil
                    self.titleLabel.text = text

                    // If differentiate without color is enabled, we should underline the button instead.
                    if #available(iOS 13.0, *) {
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
                }
            } else {
                UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
                    self.titleLabel.text = text
                    self.titleLabel.alpha = 0
                }
            }

            // Animate everything else with the usual UIView.animate
            UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
                self.titleLabel.alpha = {
                    switch status {
                    case .disabled:
                        return 0.6
                    case .succeeded:
                        return 0
                    default:
                        return 1.0
                    }
                }()

                self.backgroundColor = {
                    switch status {
                    case .enabled, .disabled, .processing:
                        return Self.appearance().backgroundColor ?? .systemBlue
                    case .succeeded:
                        return .systemGreen
                    }
                }()

                // Show/hide the lock icon, spinner
                switch status {
                case .disabled, .enabled:
                    self.lockIcon.alpha = self.titleLabel.alpha
                    self.spinner.alpha = 0
                    break
                case .processing:
                    self.lockIcon.alpha = 0
                    self.spinner.alpha = 1
                    self.spinnerCenteredToLockConstraint.isActive = true
                    self.spinnerCenteredConstraint.isActive = false
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
    }

    // MARK: - CheckProgressView

    class CheckProgressView: UIView {
        let circleLayer = CAShapeLayer()
        let checkmarkLayer = CAShapeLayer()

        override init(frame: CGRect) {
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
            circleLayer.strokeColor = UIColor.white.cgColor
            circleLayer.lineCap = .round
            circleLayer.lineWidth = 1.0
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
            checkmarkLayer.strokeColor = UIColor.white.cgColor
            checkmarkLayer.lineWidth = 1.5
            checkmarkLayer.strokeEnd = 0.0

            checkmarkLayer.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
            circleLayer.position = CGPoint(x: frame.width / 2, y: frame.height / 2)

            super.init(frame: frame)

            self.backgroundColor = UIColor.clear
            layer.addSublayer(circleLayer)
            layer.addSublayer(checkmarkLayer)
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

        func completeProgress() {
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
        }
    }
}
