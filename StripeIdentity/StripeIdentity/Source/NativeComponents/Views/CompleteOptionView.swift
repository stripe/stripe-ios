//
//  CompleteOptionView.swift
//  StripeIdentity
//
//  Created by Chen Cen on 5/4/23.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

protocol CompleteOptionViewDelegate: AnyObject {
    func didTapOption(completeOption: CompleteOptionView.CompleteOption)
}

class CompleteOptionView: UIControl {
    enum CompleteOption {
        case success
        case failure
        case successAsync
        case failureAsync
    }

    weak var delegate: CompleteOptionViewDelegate?

    private let label = UILabel()

    private let radioButton = RadioButton()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 20
        return stackView
    }()

    override var isSelected: Bool {
        didSet {
            radioButton.isOn = isSelected
        }
    }

    private let completeOption: CompleteOption

    init(title: String, option: CompleteOption) {
        self.completeOption = option
        super.init(frame: .zero)
        self.isSelected = false
        label.text = title
        stackView.addArrangedSubview(radioButton)
        stackView.addArrangedSubview(label)

        NSLayoutConstraint.activate([
            radioButton.widthAnchor.constraint(equalToConstant: 20),
            radioButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 8),
        ])

        addAndPinSubview(stackView)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
    }

    @objc fileprivate func didTap() {
        delegate?.didTapOption(completeOption: completeOption)
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CompleteOptionView {
    class RadioButton: UIView {
        struct Constants {
            static let diameter: CGFloat = 20
            static let innerDiameter: CGFloat = 8
            static let borderWidth: CGFloat = 1
        }

        public var isOn: Bool = true {
            didSet {
                update()
            }
        }

        // change the color
        public var borderColor: UIColor = IdentityUI.separatorColor {
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
            offLayer.borderColor = borderColor.cgColor
            onLayer.backgroundColor = tintColor.cgColor

            CATransaction.commit()
        }

    }

}
