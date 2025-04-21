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
@_spi(STP) public protocol Element: AnyObject, CustomDebugStringConvertible {
    /// - Note: This is set by your parent.
    var delegate: ElementDelegate? { get set }

    /// Return your UIView instance.
    var view: UIView { get }

    /// - Returns: Whether or not this Element began editing.
    func beginEditing() -> Bool

    /// Whether this element contains valid user input or not.
    var validationState: ElementValidationState { get }

    /// Text to display to the user under the item, if any.
    var subLabelText: String? { get }

    /// Whether or not this Element collects user input (e.g. a text field, dropdown, picker, checkbox).
    var collectsUserInput: Bool { get }
}

public extension Element {
    func beginEditing() -> Bool {
        return false
    }

    var validationState: ElementValidationState {
        return .valid
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
    func continueToNextField(element: Element)
}

/**
  An Element uses this delegate to present a view controller
 */
@_spi(STP) public protocol PresentingViewControllerDelegate: ElementDelegate {
    /**
     Elements will call this function to delegate presentation of a view controller
     */
    func presentViewController(viewController: UIViewController, completion: (() -> Void)?)
}

@_spi(STP) @frozen public enum ElementValidationState {
    case valid
    case invalid(error: ElementValidationError, shouldDisplay: Bool)

    /// A convenience property to check if the state is valid because it's hard to make this type Equatable
    public var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }
}

@_spi(STP) public protocol ElementValidationError: Error {
    var localizedDescription: String { get }
}

extension Element {
    public var debugDescription: String {
        return "<\(type(of: self)): \(Unmanaged.passUnretained(self).toOpaque())>"
    }
}
