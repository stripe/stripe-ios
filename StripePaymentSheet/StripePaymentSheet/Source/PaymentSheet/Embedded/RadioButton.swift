//
//  RadioButton.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 8/30/24.
//

import Foundation
import UIKit

class RadioButton: UIView {
    private let embeddedAppearance: EmbeddedAppearance

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
        embeddedAppearance.flat.radio.colorSelected?.cgColor ?? embeddedAppearance.colors.primary.cgColor
    }

    private var unselectedColor: CGColor {
        embeddedAppearance.flat.radio.colorUnselected?.cgColor ?? embeddedAppearance.colors.componentBorder.cgColor
    }

    private let didTap: () -> Void

    private lazy var outerCircle: CALayer = {
        let layer = CALayer()
        layer.bounds = CGRect(x: 0, y: 0, width: Constants.diameter, height: Constants.diameter)
        layer.cornerRadius = Constants.diameter / 2
        layer.borderWidth = Constants.borderWidth
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.borderColor = unselectedColor
        return layer
    }()

    private lazy var innerCircle: CALayer = {
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

    init(embeddedAppearance: EmbeddedAppearance = .default, didTap: @escaping () -> Void) {
        self.embeddedAppearance = embeddedAppearance
        self.didTap = didTap
        super.init(frame: .zero)
        layer.addSublayer(outerCircle)
        layer.addSublayer(innerCircle)
        update()
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        outerCircle.position = CGPoint(x: bounds.midX, y: bounds.midY)
        innerCircle.position = CGPoint(x: bounds.midX, y: bounds.midY)
    }
#if !canImport(CompositorServices)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        update()
    }
#endif

    // MARK: - Private methods

    private func update() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        outerCircle.borderColor = isOn ? selectedColor : unselectedColor
        innerCircle.isHidden = !isOn
        CATransaction.commit()
    }

    @objc private func handleTap() {
        didTap()
    }

}
