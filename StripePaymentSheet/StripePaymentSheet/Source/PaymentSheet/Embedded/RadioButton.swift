//
//  RadioButton.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 8/30/24.
//

import Foundation
import UIKit

class RadioButton: UIView {
    private let appearance: PaymentSheet.Appearance
    
    private struct Constants {
        static let diameter: CGFloat = 18
        static let innerDiameter: CGFloat = 12
        static let borderWidth: CGFloat = 1
    }

    var isOn: Bool = false {
        didSet {
            update()
        }
    }
    
    private var selectedColor: CGColor {
        appearance.paymentOptionView.paymentMethodRow.flat.radio.colorSelected?.cgColor ?? appearance.colors.primary.cgColor
    }
    
    private var unselectedColor: CGColor {
        appearance.paymentOptionView.paymentMethodRow.flat.radio.colorUnselected?.cgColor ?? appearance.colors.componentBorder.cgColor
    }
    
    private let didTap: () -> Void
    
    /// Layer for the "off" state.
    private lazy var offLayer: CALayer = {
        let layer = CALayer()
        layer.bounds = CGRect(x: 0, y: 0, width: Constants.diameter, height: Constants.diameter)
        layer.cornerRadius = Constants.diameter / 2
        layer.borderWidth = Constants.borderWidth
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.borderColor = unselectedColor
        return layer
    }()

    /// Layer for the "on" state.
    private lazy var onLayer: CALayer = {
        let layer = CALayer()
        layer.bounds = CGRect(x: 0, y: 0, width: Constants.diameter, height: Constants.diameter)
        layer.cornerRadius = Constants.diameter / 2
        layer.borderWidth = Constants.borderWidth
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.borderColor = selectedColor

        // Add and center inner circle
        layer.addSublayer(onLayerInnerCircle)
        onLayerInnerCircle.position = CGPoint(x: layer.bounds.midX, y: layer.bounds.midY)

        return layer
    }()
    
    /// Inner circle layer for the "on" state.
    private lazy var onLayerInnerCircle: CALayer = {
        let innerCircle = CALayer()
        innerCircle.backgroundColor = selectedColor
        innerCircle.cornerRadius = Constants.innerDiameter / 2
        innerCircle.bounds = CGRect(x: 0, y: 0, width: Constants.innerDiameter, height: Constants.innerDiameter)
        innerCircle.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        return innerCircle
    }()

    override var intrinsicContentSize: CGSize {
        return CGSize(width: Constants.diameter, height: Constants.diameter)
    }

    init(appearance: PaymentSheet.Appearance = .default, didTap: @escaping () -> Void) {
        self.appearance = appearance
        self.didTap = didTap
        super.init(frame: .zero)
        layer.addSublayer(offLayer)
        layer.addSublayer(onLayer)
        update()
        applyStyling()
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        offLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        onLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyStyling()
    }

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
        offLayer.borderColor = unselectedColor
        onLayer.borderColor = selectedColor
        onLayerInnerCircle.backgroundColor = selectedColor
        
        CATransaction.commit()
    }
    
    @objc private func handleTap() {
        didTap()
    }

}
