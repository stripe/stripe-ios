//
//  LinkPaymentMethodPicker-RadioButton.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 11/15/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

extension LinkPaymentMethodPicker {

    final class RadioButton: UIView {
        struct Constants {
            static let diameter: CGFloat = 20
            static let innerDiameter: CGFloat = 8
            static let borderWidth: CGFloat = 1
        }

        public var isOn: Bool = false {
            didSet {
                update()
            }
        }

        public var borderColor: UIColor = .linkControlBorder {
            didSet {
                applyStyling()
            }
        }

        /// Layer for the "off" state.
        private let offLayer: CALayer = {
            let layer = CALayer()
            layer.bounds = CGRect(x: 0, y: 0, width: Constants.diameter, height: Constants.diameter)
            layer.cornerRadius = Constants.diameter / 2
            layer.borderWidth = Constants.borderWidth
            layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            return layer
        }()

        /// Layer for the "on" state.
        private let onLayer: CALayer = {
            let layer = CALayer()
            layer.bounds = CGRect(x: 0, y: 0, width: Constants.diameter, height: Constants.diameter)
            layer.cornerRadius = Constants.diameter / 2
            layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)

            let innerCircle = CALayer()
            innerCircle.backgroundColor = UIColor.white.cgColor
            innerCircle.cornerRadius = Constants.innerDiameter / 2
            innerCircle.bounds = CGRect(x: 0, y: 0, width: Constants.innerDiameter, height: Constants.innerDiameter)
            innerCircle.anchorPoint = CGPoint(x: 0.5, y: 0.5)

            // Add and center inner circle
            layer.addSublayer(innerCircle)
            innerCircle.position = CGPoint(x: layer.bounds.midX, y: layer.bounds.midY)

            return layer
        }()

        override var intrinsicContentSize: CGSize {
            return CGSize(width: Constants.diameter, height: Constants.diameter)
        }

        init() {
            super.init(frame: .zero)
            layer.addSublayer(offLayer)
            layer.addSublayer(onLayer)
            update()
            applyStyling()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            applyStyling()
        }

        override func layoutSubviews() {
            offLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
            onLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        }

        override func tintColorDidChange() {
            super.tintColorDidChange()
            applyStyling()
        }

#if !os(visionOS)
        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            applyStyling()
        }
#endif

        // MARK: - Private methods

        private func update() {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            offLayer.isHidden = isOn
            onLayer.isHidden = !isOn
            CATransaction.commit()
        }

        private func applyStyling() {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            offLayer.borderColor = borderColor.cgColor
            onLayer.backgroundColor = tintColor.cgColor
            CATransaction.commit()
        }

    }

}
