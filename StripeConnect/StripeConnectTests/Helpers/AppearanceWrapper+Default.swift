//
//  AppearanceWrapper+Default.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 9/6/24.
//

import Foundation
@_spi(PrivateBetaConnect) @testable import StripeConnect

extension AppearanceWrapper {
    public static let `default`: AppearanceWrapper = .init(appearance: .default, traitCollection: .init())
}
