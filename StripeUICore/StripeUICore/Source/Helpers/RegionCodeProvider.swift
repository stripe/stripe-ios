//
//  RegionCodeProvider.swift
//  StripeUICore
//
//  Created by Cameron Sabol on 1/31/22.
//

import Foundation

/// Internal protocol to represent an object that provides a region code
@_spi(STP) public protocol RegionCodeProvider {
    var regionCode: String { get }
}
