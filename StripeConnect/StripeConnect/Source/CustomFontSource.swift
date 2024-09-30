//
//  CustomFontSource.swift
//  StripeConnect
//
//  Created by Chris Mays on 9/5/24.
//

import UIKit

@_spi(PrivateBetaConnect)
@available(iOS 15, *)
extension EmbeddedComponentManager {

    /// Use a `CustomFontSource` pass custom fonts embedded in your app's binary when initializing a
    /// `EmbeddedComponentManager`.
    /// - Seealso: https://docs.stripe.com/connect/get-started-connect-embedded-components#customize-the-look-of-connect-embedded-components
    /// - Seealso: https://developer.apple.com/documentation/uikit/text_display_and_fonts/adding_a_custom_font_to_your_app
    public struct CustomFontSource {
        let family: String
        let style: String?
        let weight: String?
        let src: FontSource

        /**
         Initializes a CustomFontSource from a base font and its original file URL
         - Parameters:
         - font: A custom font embedded into your app's binary
         - fileUrl: The local file URL corresponding to the custom font
         
         - Note: The font's size does not impact the appearance of the component.
         To adjust the font sizes used in components, use `EmbeddedComponentManager.Appearance`
         
         - Throws: Error if the font couldn't be loaded from the given URL
         */
        public init(font: UIFont, fileUrl: URL) throws {
            guard fileUrl.isFileURL else {
                throw FontLoadError.notFileURL
            }

            let fontData = try Data(contentsOf: fileUrl)
            self.src = .init(fileType: fileUrl.pathExtension, encoding: fontData.base64EncodedString())
            family = font.familyName
            style = font.isItalic ? "italic" : nil
            self.weight = font.weight.cssValue
        }

        enum FontLoadError: Error, CustomDebugStringConvertible {
            case notFileURL

            var debugDescription: String {
                switch self {
                case .notFileURL:
                    return "Only file URLs can be used for custom fonts"
                }
            }
        }
    }

    struct FontSource: Encodable, Equatable {
        let fileType: String
        let encoding: String

        // TODO: CAUI-2844 Move to encoding FontSource directly instead of using a string.
        var stringValue: String {
            "url(data:font/\(fileType);charset=utf-8;base64,\(encoding))"
        }
    }
}
