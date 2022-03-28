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
    
    private let activityIndicator: ActivityIndicator = ActivityIndicator(size: .medium)
    
    lazy var view: UIView = {
        let stackView = UIStackView(arrangedSubviews: [emailAddressElement.view, activityIndicator])
        stackView.spacing = 0
        stackView.axis = .horizontal
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
        activityIndicator.startAnimating()
    }
    
    public func stopAnimating() {
        activityIndicator.stopAnimating()
    }
    
    public init(defaultValue: String? = nil) {
        emailAddressElement = TextFieldElement.Address.makeEmail(defaultValue: defaultValue)
        emailAddressElement.delegate = self
    }
}

extension LinkEmailElement: ElementDelegate {
    func didUpdate(element: Element) {
        delegate?.didUpdate(element: self)
    }
    
    func didFinishEditing(element: Element) {
        delegate?.didFinishEditing(element: self)
    }
    
    
}
