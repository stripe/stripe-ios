//
//  StripeAPIConfiguration.swift
//  StripeCore
//
//  Created by Mel Ludowise on 5/17/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// Shared configurations across all Stripe frameworks.
@_spi(STP) public struct StripeAPIConfiguration {

    public static let sharedUrlSessionConfiguration = URLSessionConfiguration.default

}
