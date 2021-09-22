//
//  FormElement.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/7/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/**
 A simple container of Elements.
 Displays its views in a vertical stack.
 Coordinates focus between its child Elements.
 */
@_spi(STP) public class FormElement {
    weak public var delegate: ElementDelegate?
    lazy var formView: FormView = {
        return FormView(viewModel: viewModel)
    }()
    public let elements: [Element]

    // MARK: - ViewModel
    
    struct ViewModel {
        let elements: [UIView]
    }
    var viewModel: ViewModel {
        return ViewModel(elements: elements.map({ $0.view }))
    }
    
    // MARK: - Initializer
    
    public init(elements: [Element?]) {
        self.elements = elements.compactMap { $0 }
        defer {
            self.elements.forEach { $0.delegate = self }
        }
    }
}

// MARK: - Element

extension FormElement: Element {
    public var view: UIView {
        return formView
    }
}

// MARK: - ElementDelegate

extension FormElement: ElementDelegate {
    public func didFinishEditing(element: Element) {
        let remainingElements = elements.drop { $0 !== element }.dropFirst()
        for next in remainingElements {
            if next.becomeResponder() {
                UIAccessibility.post(notification: .screenChanged, argument: next.view)
                return
            }
        }
        // Failed to become first responder
        delegate?.didFinishEditing(element: self)
    }
    
    public func didUpdate(element: Element) {
        delegate?.didUpdate(element: self)
    }
}
