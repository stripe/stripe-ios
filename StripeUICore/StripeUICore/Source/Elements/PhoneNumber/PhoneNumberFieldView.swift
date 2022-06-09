//
//  PhoneNumberFieldView.swift
//  StripeUICore
//
//  Created by Cameron Sabol on 11/2/21.
//

import UIKit

/**
 Containing view for a PhoneNumberElement
 
 For internal SDK use only.
 */
@objc(STP_Itnternal_PhoneNumberFieldView)
class PhoneNumberFieldView: UIView, FloatingPlaceholderContentView {
    let labelShouldFloat: Bool = true
    var defaultResponder: UIView {
        if let textFieldView = numberTextView as? TextFieldView {
            return textFieldView.textField
        }
        return numberTextView
    }
    
    private let regionDropDown: UIView
    private let regionPrefixLabel: UILabel
    private let numberTextView: UIView
    
    required init(regionDropDown: UIView,
                  regionPrefixLabel: UILabel,
                  numberTextView: UIView) {
        self.regionDropDown = regionDropDown
        self.numberTextView = numberTextView
        self.regionPrefixLabel = regionPrefixLabel

        super.init(frame: .zero)

        let container = UIView()
        regionPrefixLabel.setContentHuggingPriority(.required, for: .horizontal)
        container.addAndPinSubview(regionPrefixLabel, insets: .insets(top: 0, leading: 0, bottom: 0, trailing: 4))
        let stackView = UIStackView(arrangedSubviews: [regionDropDown, container])
        stackView.alignment = .center
        stackView.spacing = 4

        let containerView = UIView()
        containerView.addAndPinSubview(stackView)

        let topLevelStackView = UIStackView(arrangedSubviews: [containerView, numberTextView])
        topLevelStackView.alignment = .center
        topLevelStackView.translatesAutoresizingMaskIntoConstraints = false
        topLevelStackView.distribution = .equalSpacing

        addSubview(topLevelStackView)

        NSLayoutConstraint.activate([
            topLevelStackView.topAnchor.constraint(equalTo: topAnchor),
            topLevelStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            topLevelStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topLevelStackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: 0)
        ])
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)

        if hitView === self {
            // Forward outside taps to default responder
            return defaultResponder
        } else {
            return hitView
        }
    }
}
