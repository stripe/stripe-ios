//
//  RegionCodeProvider.swift
//  StripeUICore
//
//  Created by Cameron Sabol on 1/31/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

/// Internal protocol to represent an object that provides a region code
@_spi(InternalOnlyAPI) public protocol RegionCodeProvider {
    var regionCode: String { get }
}
