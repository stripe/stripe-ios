//
//  StripeConnectInstanceCustomFontSource.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/3/24.
//

import UIKit

extension StripeConnectInstance {
    public struct CustomFontSource {
        public var family: String
        public var url: URL
        public var italic: Bool
        public var weight: UIFont.Weight

        public init(family: String,
                    url: URL,
                    italic: Bool,
                    weight: UIFont.Weight) {
            self.family = family
            self.url = url
            self.italic = italic
            self.weight = weight
        }

        var src: String? {
            if !url.isFileURL {
                return "url('\(url.absoluteString)')"
            }
            if let fontData = try? Data(contentsOf: url) {
                let base64Font = fontData.base64EncodedString()

                let ext = url.pathExtension
                return "url(data:font/\(ext);charset=utf-8;base64,\(base64Font))"
            }
            assertionFailure("Could not encode font \(url.absoluteString)")
            return nil
        }

        var asJsonDictionary: [String: String]? {
            guard let src else { return nil }
            return [ "family": family,
                     "style": italic ? "italic" : "normal",
                     "weight": weight.cssValue ?? "normal",
                     "src": src, ]
        }
    }
}
