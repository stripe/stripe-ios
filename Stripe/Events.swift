//
//  Events.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/// Sends the event down the view hierarchy
func sendEventToSubviews(_ event: STPEvent, from view: UIView) {
    if let view = view as? EventHandler {
        view.handleEvent(event)
    }
    for subview in view.subviews {
        sendEventToSubviews(event, from: subview)
    }
}

enum STPEvent {
    case shouldEnableUserInteraction
    case shouldDisableUserInteraction
}

protocol EventHandler {
    func handleEvent(_ event: STPEvent)
}
