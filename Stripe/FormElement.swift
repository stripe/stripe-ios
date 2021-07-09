//
//  FormElement.swift
//  StripeiOS
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
class FormElement {
    weak var delegate: ElementDelegate?
    lazy var formView: FormView = {
        return FormView(viewModel: viewModel)
    }()
    let elements: [Element]
    let paramsUpdater: (IntentConfirmParams) -> IntentConfirmParams

    // MARK: - ViewModel
    
    struct ViewModel {
        let elements: [UIView]
    }
    var viewModel: ViewModel {
        return ViewModel(elements: elements.map({ $0.view }))
    }
    
    // MARK: - Initializer
    
    init(
        elements: [Element?],
        paramsUpdater: @escaping (IntentConfirmParams) -> IntentConfirmParams = { $0 }
    ) {
        self.elements = elements.compactMap { $0 }
        self.paramsUpdater = paramsUpdater
        defer {
            self.elements.forEach { $0.delegate = self }
        }
    }
}

// MARK: - Element

extension FormElement: Element {
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        let params = paramsUpdater(params)
        return elements.reduce(params) { (params: IntentConfirmParams?, element: Element) in
            guard let params = params else {
                return nil
            }
            return element.updateParams(params: params)
        }
    }
    
    var view: UIView {
        return formView
    }
}

// MARK: - ElementDelegate

extension FormElement: ElementDelegate {
    func didFinishEditing(element: Element) {
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
    
    func didUpdate(element: Element) {
        delegate?.didUpdate(element: self)
    }
}
