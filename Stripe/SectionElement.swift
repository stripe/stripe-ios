//
//  SectionElement.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/6/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/**
 A simple container element with an optional title and an error, and draws a border around its elements.
 Chooses which of its sub-elements' errors to display.
 */
class SectionElement {

    weak var delegate: ElementDelegate?
    lazy var sectionView: SectionView = {
        return SectionView(viewModel: viewModel)
    }()
    var viewModel: SectionViewModel {
        return ViewModel(
            views: elements.map({ $0.view }),
            title: title,
            error: error
        )
    }
    var elements: [Element] {
        didSet {
            sectionView.update(with: viewModel)
            delegate?.didUpdate(element: self)
        }
    }
    let title: String?
    var error: String? {
        // Get the first TextFieldElement that is invalid and has a displayable error
        for element in elements.compactMap({ $0 as? TextFieldElement }) {
            guard case .invalid(let error) = element.validationState else {
                continue
            }
            if error.shouldDisplay(isUserEditing: element.isEditing) {
                return error.localizedDescription
            }
        }
        return nil
    }

    // MARK: - ViewModel
    
    struct ViewModel {
        let views: [UIView]
        let title: String?
        var error: String? = nil
    }

    // MARK: - Initializers
    
    init(title: String? = nil, elements: [Element]) {
        self.title = title
        self.elements = elements
        
        defer {
            elements.forEach {
                $0.delegate = self
            }
        }
    }
    
    convenience init(_ element: Element) {
        self.init(title: nil, elements: [element])
    }
}

// MARK: - Element

extension SectionElement: Element {
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        // Ask each sub-element to update params
        return elements.reduce(params) { (params: IntentConfirmParams?, element: Element) in
            guard let params = params else {
                return nil
            }
            return element.updateParams(params: params)
        }
    }
    
    func becomeResponder() -> Bool {
        return elements.first?.becomeResponder() ?? false
    }
    
    var view: UIView {
        return sectionView
    }
}

// MARK: - ElementDelegate

extension SectionElement: ElementDelegate {
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
        // Glue: Update the view and our delegate
        sectionView.update(with: viewModel)
        delegate?.didUpdate(element: self)
    }
}
