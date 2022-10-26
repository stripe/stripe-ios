//
//  String+RegionCodeProvider.swift
//  StripeUICore
//
//  Created by Cameron Sabol on 1/31/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

/// Default conformance of String to RegionCodeProvider
@_spi(STP) extension String: RegionCodeProvider {
    public var regionCode: String {
        return self
    }
}
