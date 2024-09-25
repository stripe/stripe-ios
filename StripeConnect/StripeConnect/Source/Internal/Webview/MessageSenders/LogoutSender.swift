//
//  LogoutSender.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 9/24/24.
//

import Foundation

struct LogoutSender: MessageSender {
    let name = "logout"
    let payload = VoidPayload()
}
