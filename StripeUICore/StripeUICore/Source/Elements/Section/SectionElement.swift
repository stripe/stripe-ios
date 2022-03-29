//
//  SectionElement.swift
//  StripeUICore
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
@_spi(STP) public class SectionElement {

    weak public var delegate: ElementDelegate?
    lazy var sectionView: SectionView = {
        return SectionView(viewModel: viewModel)
    }()
    var viewModel: SectionViewModel {
        return ViewModel(
            views: elements.map({ $0.view }),
            title: title,
            error: error,
            subLabel: subLabel
        )
    }
    public var elements: [Element] {
        didSet {
            elements.forEach {
                $0.delegate = self
            }
            sectionView.update(with: viewModel)
            delegate?.didUpdate(element: self)
        }
    }
    let title: String?
    var error: String? {
        // Display the error text of the first element with an error
        elements.compactMap({ $0.errorText }).first
    }

    var subLabel: String? {
        elements.compactMap({ $0.subLabelText }).first
    }


    // MARK: - ViewModel
    
    struct ViewModel {
        let views: [UIView]
        let title: String?
        var error: String? = nil
        var subLabel: String? = nil
    }

    // MARK: - Initializers
    
    public init(title: String? = nil, elements: [Element]) {
        self.title = title
        self.elements = elements
        
        defer {
            elements.forEach {
                $0.delegate = self
            }
        }
    }
    
    public convenience init(_ element: Element) {
        self.init(title: nil, elements: [element])
    }
}

// MARK: - Element

extension SectionElement: Element {
    public func becomeResponder() -> Bool {
        return elements.first?.becomeResponder() ?? false
    }
    
    public var view: UIView {
        return sectionView
    }
}

// MARK: - ElementDelegate

extension SectionElement: ElementDelegate {
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
        // Glue: Update the view and our delegate
        sectionView.update(with: viewModel)
        delegate?.didUpdate(element: self)
    }
}
