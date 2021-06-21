//
//  StaticElement.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/18/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

class StaticElement {
    var delegate: ElementDelegate?
    let view: UIView
    var isHidden: Bool = false {
        didSet {
            view.isHidden = isHidden
        }
    }
    
    init(view: UIView) {
        self.view = view
    }
}

/// :nodoc:
extension StaticElement: Element {
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        return params
    }
    
    var validationState: ElementValidationState {
        return .valid
    }
}
