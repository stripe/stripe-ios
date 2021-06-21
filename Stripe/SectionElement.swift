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
final class SectionElement {

    weak var delegate: ElementDelegate?
    lazy var sectionView: SectionView = {
        return SectionView(viewModel: viewModel)
    }()
    var viewModel: SectionViewModel {
        return ViewModel(
            elements: elements.map({ $0.view }),
            title: title,
            error: error
        )
    }
    let elements: [Element]
    let title: String?
    var error: String? {
        // Get the first Element that is invalid and has a displayable error
        for element in elements {
            guard case .invalid(let error) = element.validationState else {
                continue
            }
            if let error = error as? TextFieldValidationError,
               let element = element as? TextFieldElement {
                if error.shouldDisplay(isUserEditing: element.isEditing) {
                    return error.localizedDescription
                }
            } else {
                return error.localizedDescription
            }
        }
        return nil
    }

    // MARK: - ViewModel
    
    struct ViewModel {
        let elements: [UIView]
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
    var validationState: ElementValidationState {
        // Return the first invalid element's validation state.
        return elements.reduce(ElementValidationState.valid) { validationState, element in
            guard case .valid = validationState else {
                return validationState
            }
            return element.validationState
        }
    }
    
    var view: UIView {
        return sectionView
    }
}

// MARK: - ElementDelegate

extension SectionElement: ElementDelegate {
    func didUpdate(element: Element) {
        // Glue: Update the view and our delegate
        sectionView.update(with: viewModel)
        delegate?.didUpdate(element: self)
    }
}
