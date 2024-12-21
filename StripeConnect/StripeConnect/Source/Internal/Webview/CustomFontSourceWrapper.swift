//
//  CustomFontSourceWrapper.swift
//  StripeConnect
//
//  Created by Chris Mays on 9/6/24.
//

import Foundation

@available(iOS 15, *)
struct CustomFontSourceWrapper: Encodable {
    let customFontSource: EmbeddedComponentManager.CustomFontSource
    enum CodingKeys: String, CodingKey {
        case family, style, weight, src
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(customFontSource.family, forKey: .family)
        try container.encodeIfPresent(customFontSource.style, forKey: .style)
        try container.encodeIfPresent(customFontSource.weight, forKey: .weight)
        try container.encode(customFontSource.src.stringValue, forKey: .src)
    }
}
