//
//  LinkEmailElement.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 1/13/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeUICore

class LinkEmailElement: Element {
    weak var delegate: ElementDelegate? = nil
    
    private let emailAddressElement: TextFieldElement
    
    private let activityIndicator: ActivityIndicator = {
        // TODO: Consider adding the activity indicator to TextFieldView
        let activityIndicator = ActivityIndicator(size: .medium)
        activityIndicator.setContentCompressionResistancePriority(.required, for: .horizontal)
        return activityIndicator
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [emailAddressElement.view, activityIndicator])
        stackView.spacing = 0
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = .insets(
            top: 0,
            leading: 0,
            bottom: 0,
            trailing: ElementsUI.contentViewInsets.trailing
        )
        return stackView
    }()

    lazy var view: UIView = {
        return FormView(viewModel: FormElement.ViewModel(elements: [stackView], bordered: true))
    }()
    
    public var emailAddressString: String? {
        return emailAddressElement.text
    }
    
    public var validationState: TextFieldElement.ValidationState {
        return emailAddressElement.validationState
    }
    
    public var indicatorTintColor: UIColor {
        get {
            return activityIndicator.color
        }

        set {
            activityIndicator.color = newValue
        }
    }
    
    public func startAnimating() {
        UIView.performWithoutAnimation {
            activityIndicator.startAnimating()
            stackView.setNeedsLayout()
            stackView.layoutSubviews()
        }
    }
    
    public func stopAnimating() {
        UIView.performWithoutAnimation {
            activityIndicator.stopAnimating()
            stackView.setNeedsLayout()
            stackView.layoutSubviews()
        }
    }
    
    public init(defaultValue: String? = nil) {
        emailAddressElement = TextFieldElement.makeEmail(defaultValue: defaultValue)
        emailAddressElement.delegate = self
    }
}

extension LinkEmailElement: ElementDelegate {
    func didUpdate(element: Element) {
        delegate?.didUpdate(element: self)
    }
    
    func continueToNextField(element: Element) {
        delegate?.continueToNextField(element: self)
    }
}
