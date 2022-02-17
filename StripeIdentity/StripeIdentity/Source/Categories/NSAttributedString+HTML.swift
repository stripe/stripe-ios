//
//  NSAttributedString+HTML.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/1/22.
//
import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

/// Specifies how to style HTML used to generate an NSAttributedString.
struct HTMLStyle {
    static let `default` = HTMLStyle(
        bodyFont: UIFont.preferredFont(forTextStyle: .body, weight: .regular),
        bodyColor: CompatibleColor.label,
        h1Font: UIFont.preferredFont(forTextStyle: .title1),
        h2Font: UIFont.preferredFont(forTextStyle: .title2),
        h3Font: UIFont.preferredFont(forTextStyle: .title3),
        h4Font: UIFont.preferredFont(forTextStyle: .headline),
        h5Font: UIFont.preferredFont(forTextStyle: .subheadline),
        h6Font: UIFont.preferredFont(forTextStyle: .footnote),
        isLinkUnderlined: false
    )

    let bodyFont: UIFont
    let bodyColor: UIColor?

    let h1Font: UIFont?
    let h1Color: UIColor?

    let h2Font: UIFont?
    let h2Color: UIColor?

    let h3Font: UIFont?
    let h3Color: UIColor?

    let h4Font: UIFont?
    let h4Color: UIColor?

    let h5Font: UIFont?
    let h5Color: UIColor?

    let h6Font: UIFont?
    let h6Color: UIColor?

    let isLinkUnderlined: Bool

    init(
        bodyFont: UIFont,
        bodyColor: UIColor? = nil,
        h1Font: UIFont? = nil,
        h1Color: UIColor? = nil,
        h2Font: UIFont? = nil,
        h2Color: UIColor? = nil,
        h3Font: UIFont? = nil,
        h3Color: UIColor? = nil,
        h4Font: UIFont? = nil,
        h4Color: UIColor? = nil,
        h5Font: UIFont? = nil,
        h5Color: UIColor? = nil,
        h6Font: UIFont? = nil,
        h6Color: UIColor? = nil,
        isLinkUnderlined: Bool = false
    ) {
        self.bodyFont = bodyFont
        self.bodyColor = bodyColor
        self.h1Font = h1Font
        self.h1Color = h1Color
        self.h2Font = h2Font
        self.h2Color = h2Color
        self.h3Font = h3Font
        self.h3Color = h3Color
        self.h4Font = h4Font
        self.h4Color = h4Color
        self.h5Font = h5Font
        self.h5Color = h5Color
        self.h6Font = h6Font
        self.h6Color = h6Color
        self.isLinkUnderlined = isLinkUnderlined
    }

    fileprivate static func cssText(
        _ cssName: String,
        font: UIFont?,
        color: UIColor?
    ) -> String {
        guard font != nil || color != nil else {
            return ""
        }

        let fontAttributes = font.map { font -> String in
            // If the specified font is the same family as the system font,
            // then use "-apple-system" instead. Otherwise, the html renderer will
            // only use the non-bold variation of the system font, breaking any bold
            // font configurations.
            var familyName = font.familyName
            if familyName == UIFont.systemFont(ofSize: font.pointSize).familyName {
                familyName = "-apple-system"
            }

            let fontWeight = font.fontDescriptor.symbolicTraits.contains(.traitBold)
            ? "bold"
            : "regular"

            return """
              font-family: "\(familyName)";
              font-size: \(font.pointSize);
              font-weight: "\(fontWeight)";
            """
        }

        let colorAttributes = color.map { color -> String in
            return "color: \(color.cssValue);"
        }

        return """
        \(cssName) {
        \(fontAttributes ?? "")
        \(colorAttributes ?? "")
        }
        """
    }

    /// Constructs a style HTML tag from the properties of this HTMLStyle
    fileprivate var styleElementText: String {
        var text = "<style>\n"

        text += HTMLStyle.cssText("body", font: bodyFont, color: bodyColor)
        text += HTMLStyle.cssText("h1", font: h1Font, color: h1Color)
        text += HTMLStyle.cssText("h2", font: h2Font, color: h2Color)
        text += HTMLStyle.cssText("h3", font: h3Font, color: h3Color)
        text += HTMLStyle.cssText("h4", font: h4Font, color: h4Color)
        text += HTMLStyle.cssText("h5", font: h5Font, color: h5Color)
        text += HTMLStyle.cssText("h6", font: h6Font, color: h6Color)

        text += """
        a {
          text-decoration: \(isLinkUnderlined ? "underline" : "none");
        }
        </style>
        """

        return text
    }
}

extension NSAttributedString {
    /**
     Initializes an NSAttributedString from HTML with the specified style.

     - Note:
     By default, when an attributed string is built from HTML, the font defaults
     to Times New Roman with 11pt font. Setting a font on the UILabel or
     UITextView displaying the attributed string does not override the font.

     This initializer wraps the HTML string in a `<style>` tag so the attributed
     string is styled according to the style argument.

     - Parameters:
       - htmlText: HTML text to generate the attributed string from
       - style: Specifies how the HTML should be styled.
     */
    convenience init(
        htmlText: String,
        style: HTMLStyle
    ) throws {
        let htmlTemplate = """
        <html>
            <head>\(style.styleElementText)</head>
            <body>\(htmlText)</body>
        </html>
        """
        let data = Data(htmlTemplate.utf8)
        try self.init(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html
            ],
            documentAttributes: nil
        )
    }
}

private extension UIColor {
    var cssValue: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 1

        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return String(
            format: "rgba(%.0f, %.0f, %.0f, %.0f)",
            red * 255,
            green * 255,
            blue * 255,
            alpha * 255
        )
    }
}
