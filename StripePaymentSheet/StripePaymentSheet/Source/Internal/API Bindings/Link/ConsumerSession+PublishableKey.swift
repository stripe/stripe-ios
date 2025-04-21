//
//  ConsumerSession+PublishableKey.swift
//  StripePaymentSheet
//
//  Created by Bill Meltsner on 2/7/23.
//  Copyright © 2023 Stripe, Inc. All rights reserved.
//

import Foundation

extension ConsumerSession {
    final class SessionWithPublishableKey: Decodable {
        let consumerSession: ConsumerSession
        let publishableKey: String
        let authSessionClientSecret: String?

        init(
            consumerSession: ConsumerSession,
            publishableKey: String,
            authSessionClientSecret: String? = nil
        ) {
            self.consumerSession = consumerSession
            self.publishableKey = publishableKey
            self.authSessionClientSecret = authSessionClientSecret
        }
    }
}
