//
//  Events.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Sends the event down the view hierarchy
@_spi(STP) public func sendEventToSubviews(_ event: STPEvent, from view: UIView) {
    if let view = view as? EventHandler {
        view.handleEvent(event)
    }
    for subview in view.subviews.compactMap({ $0 as? UIView }) {
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
