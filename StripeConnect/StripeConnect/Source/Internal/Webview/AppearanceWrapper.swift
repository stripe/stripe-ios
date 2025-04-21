//
//  AppearanceWrapper.swift
//  StripeConnect
//
//  Created by Chris Mays on 9/6/24.
//

import UIKit

@available(iOS 15, *)
struct AppearanceWrapper: Encodable {
    let appearance: Appearance
    let traitCollection: UITraitCollection

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(appearance.asDictionary(traitCollection: traitCollection), forKey: StringCodingKey("variables"))
    }
}
