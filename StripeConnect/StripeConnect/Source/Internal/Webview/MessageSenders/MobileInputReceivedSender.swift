//
//  MobileInputReceivedSender.swift
//  StripeConnect
//
//  Created by Chris Mays on 2/12/25.
//

enum Input: String, Equatable, Codable {
    case close = "closeButtonPressed"
}

struct MobileInputReceivedSender: MessageSender {
    struct Payload: Codable, Equatable {
        var input: Input
    }
    let name: String = "mobileInputReceived"
    let payload: Payload = .init(input: .close)
}
