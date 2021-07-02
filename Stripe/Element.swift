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
 */
protocol Element: AnyObject {
    /**
     Modify the params according to your input, or return nil if you are invalid.
     */
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams?

    /**
     Whether or not the detail(s) you're collecting is valid.
     */
    var validationState: ElementValidationState { get }
    
    /**
     - Note: This is set by your parent.
     */
    var delegate: ElementDelegate? { get set }
    
    /**
     Return your UIView instance.
     */
    var view: UIView { get }
}

// MARK: Element default implementation

extension Element {
    var validationState: ElementValidationState {
        return .valid
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
}
