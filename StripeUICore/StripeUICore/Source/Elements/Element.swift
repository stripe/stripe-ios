//
//  Element.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Element

/**
 Conform to this protocol to participate in the collection of details for a Payment/SetupIntent.
 
 Think of this as a light-weight, specialized view controller.
 */
@_spi(STP) public protocol Element: AnyObject {
    /**
     - Note: This is set by your parent.
     */
    var delegate: ElementDelegate? { get set }
    
    /**
     Return your UIView instance.
     */
    var view: UIView { get }
    
    /**
     - Returns: Whether or not this object is now the first-responder.
     */
    func becomeResponder() -> Bool
    
    /**
     The error text to display to the user, if any.
     */
    var errorText: String? { get }

    /**
     Text to display to the user under the item, if any.
     */
    var subLabelText: String? { get }
}

public extension Element {
    func becomeResponder() -> Bool {
        return view.becomeFirstResponder()
    }
    
    var errorText: String? {
        return nil
    }

    var subLabelText: String? {
        return nil
    }
}

// MARK: - ElementDelegate

/**
  An Element uses this delegate to communicate events to its owner, which is typically also an Element.
 */
@_spi(STP) public protocol ElementDelegate: AnyObject {
    /**
     This method is called whenever your public/internally visable state changes.
     Note for implementors: Be sure to chain this call upwards to your own ElementDelegate.
     */
    func didUpdate(element: Element)
    
    /**
     This method is called when the user finishes editing the caller e.g., by pressing the 'return' key.
     Note for implementors: Be sure to chain this call upwards to your own ElementDelegate.
     */
    func didFinishEditing(element: Element)
}

extension Element {
    /// A poorly named convenience method that returns all Elements underneath this Element, including this Element.
    func getAllSubElements() -> [Element] {
        switch self {
        case let form as FormElement:
            return [form] + form.elements.flatMap { $0.getAllSubElements() }
        case let section as SectionElement:
            return [section] + section.elements.flatMap { $0.getAllSubElements() }
        default:
            return [self]
        }
    }
}
