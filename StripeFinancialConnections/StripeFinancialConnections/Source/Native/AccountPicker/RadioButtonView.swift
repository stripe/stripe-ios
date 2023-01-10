//
//  RadioButtonView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/18/22.
//

import Foundation
import UIKit

final class RadioButtonView: UIView {
    private struct Constants {
        static let diameter: CGFloat = 20
        static let innerDiameter: CGFloat = 8
        static let borderWidth: CGFloat = 1
    }

    var isSelected: Bool = false {
        didSet {
            updateViewBasedOffSelectionState()
        }
    }

    private let unselectedStateLayer: CALayer = {
        let unselectedStateLayer = CALayer()
        unselectedStateLayer.bounds = CGRect(x: 0, y: 0, width: Constants.diameter, height: Constants.diameter)
        unselectedStateLayer.cornerRadius = Constants.diameter / 2
        unselectedStateLayer.borderWidth = Constants.borderWidth
        unselectedStateLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        return unselectedStateLayer
    }()

    private let selectedStateLayer: CALayer = {
        let selectedStateLayer = CALayer()
        selectedStateLayer.bounds = CGRect(x: 0, y: 0, width: Constants.diameter, height: Constants.diameter)
        selectedStateLayer.cornerRadius = Constants.diameter / 2
        selectedStateLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        let innerCircleLayer = CALayer()
        innerCircleLayer.backgroundColor = UIColor.white.cgColor
        innerCircleLayer.cornerRadius = Constants.innerDiameter / 2
        innerCircleLayer.bounds = CGRect(x: 0, y: 0, width: Constants.innerDiameter, height: Constants.innerDiameter)
        innerCircleLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        // Add and center inner circle
        selectedStateLayer.addSublayer(innerCircleLayer)
        innerCircleLayer.position = CGPoint(x: selectedStateLayer.bounds.midX, y: selectedStateLayer.bounds.midY)

        return selectedStateLayer
    }()

    override var intrinsicContentSize: CGSize {
        return CGSize(width: Constants.diameter, height: Constants.diameter)
    }

    init() {
        super.init(frame: .zero)
        layer.addSublayer(unselectedStateLayer)
        layer.addSublayer(selectedStateLayer)
        unselectedStateLayer.borderColor = UIColor.borderNeutral.cgColor
        selectedStateLayer.backgroundColor = UIColor.textBrand.cgColor

        updateViewBasedOffSelectionState()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func layoutSubviews() {
        unselectedStateLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        selectedStateLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
    }

    private func updateViewBasedOffSelectionState() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        unselectedStateLayer.isHidden = isSelected
        selectedStateLayer.isHidden = !unselectedStateLayer.isHidden
        CATransaction.commit()
    }
}
