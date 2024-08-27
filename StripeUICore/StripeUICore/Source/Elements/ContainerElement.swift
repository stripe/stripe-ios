//
//  ContainerElement.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 3/25/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/**
 A protocol for Elements that contain other Elements. 
 It offers default implementations for the methods required to participate in the Element hierarchy.
 
 - Note:You still need to set your sub-element's delegates = self!
 */
@_spi(STP) public protocol ContainerElement: Element, ElementDelegate {
    var elements: [Element] { get }
}

extension ContainerElement {
    // MARK: - Element
    public var collectsUserInput: Bool {
        // Returns true if any of the child elements collect user input
        return elements.reduce(false) { partialResult, element in
            element.collectsUserInput || partialResult
        }
    }

    public func beginEditing() -> Bool {
        guard !view.isHidden else {
            // Prevent focusing on a child element if the container is hidden.
            return false
        }

        return elements.first?.beginEditing() ?? false
    }

    public var validationState: ElementValidationState {
        elements.first {
            if case .valid = $0.validationState {
                return false
            }
            return true
        }?.validationState ?? .valid
    }

    // MARK: - ElementDelegate

    public func didUpdate(element: Element) {
        // Glue: Update the view and our delegate
        delegate?.didUpdate(element: self)
    }

    public func continueToNextField(element: Element) {
        let remainingElements = elements
            .drop { $0 !== element } // Drop elements (starting from the first) until we find `element`
            .dropFirst() // Drop `element` too
        for next in remainingElements {
            // Don't auto select hidden elements
            if !(next is SectionElement.HiddenElement),
                !next.view.isHidden,
                next.beginEditing() {
                UIAccessibility.post(notification: .screenChanged, argument: next.view)
                return
            }
        }
        // Failed to become first responder
        delegate?.continueToNextField(element: self)
    }
}

extension ContainerElement {
    public var debugDescription: String {
        return "<\(type(of: self)): \(Unmanaged.passUnretained(self).toOpaque())>" + subElementDebugDescription
    }

    public var subElementDebugDescription: String  {
        elements.reduce("") { partialResult, element in
            partialResult + "\n└─ \(String(describing: element).replacingOccurrences(of: "└─", with: "   └─"))"
        }
    }
}
