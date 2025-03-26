//
//  StaticElement.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/18/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

/**
 A inert wrapper around a view.
 */
@_spi(STP) public class StaticElement: Element {
    public let collectsUserInput: Bool = false
    weak public var delegate: ElementDelegate?
    public let view: UIView
    public var isHidden: Bool = false {
        didSet {
            view.isHidden = isHidden
        }
    }

    public init(view: UIView) {
        self.view = view
    }
}
