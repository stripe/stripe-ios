//
//  Element.swift
//  StripeiOS
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
protocol Element: AnyObject {
    /**
     Modify the params according to your input, or return nil if you are invalid.
     */
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams?

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
}

extension Element {
    func becomeResponder() -> Bool {
        return view.becomeFirstResponder()
    }
}

// MARK: - ElementDelegate

/**
  An Element uses this delegate to communicate events to its owner, which is typically also an Element.
 */
protocol ElementDelegate: AnyObject {
    /**
     This method is called whenever your public/internally visable state changes.
     */
    func didUpdate(element: Element)
    
    /**
     This method is called when the user finishes editing the caller e.g., by pressing the 'return' key.
     */
    func didFinishEditing(element: Element)
}
