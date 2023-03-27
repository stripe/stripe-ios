//
//  Events.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/// Sends the event down the view hierarchy
@_spi(STP) public func sendEventToSubviews(_ event: STPEvent, from view: UIView) {
    if let view = view as? EventHandler {
        view.handleEvent(event)
    }
    for subview in view.subviews {
        sendEventToSubviews(event, from: subview)
    }
}

@frozen @_spi(STP) public enum STPEvent {
    case shouldEnableUserInteraction
    case shouldDisableUserInteraction
    case viewDidAppear
}

@_spi(STP) public protocol EventHandler {
    func handleEvent(_ event: STPEvent)
}
