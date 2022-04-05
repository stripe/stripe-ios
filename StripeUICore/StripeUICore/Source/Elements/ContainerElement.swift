//
//  ContainerElement.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 3/25/22.
//

import Foundation
import UIKit

/**
 A convenience protocol for Elements that contain other Elements.
 It offers default implementations for the methods required to participate in the Element hierarchy.
 
 - Note:You still need to set your sub-element's delegates = self!
 */
@_spi(STP) public protocol ContainerElement: Element, ElementDelegate {
    var elements: [Element] { get }
}

extension ContainerElement {
    // MARK: - Element
    
    public func beginEditing() -> Bool {
        return elements.first?.beginEditing() ?? false
    }
    
    public var errorText: String? {
        // Display the error text of the first element with an error
        elements.compactMap({ $0.errorText }).first
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
            if next.beginEditing() {
                UIAccessibility.post(notification: .screenChanged, argument: next.view)
                return
            }
        }
        // Failed to become first responder
        delegate?.continueToNextField(element: self)
    }
}
