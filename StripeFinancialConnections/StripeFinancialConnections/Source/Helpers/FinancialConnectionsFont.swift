//
//  FinancialConnectionsFont.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 5/2/23.
//

import Foundation
import UIKit

// A wrapper around `UIFont` that allows us to specify a `lineHeight`.
// `UIFont` does not support modifying `lineHeight` so this struct
// helps us to easily pass around font + line height.
struct FinancialConnectionsFont {

    let uiFont: UIFont
    let lineHeight: CGFloat

    // An estimated "top padding of the font character"
    var topPadding: CGFloat {
        return max(0, ((lineHeight - uiFont.lineHeight) / 2)) + (uiFont.ascender - uiFont.capHeight)
    }

    enum HeadingToken {
        /// 20 size / 28 line height / 700 weight
        case medium
        /// 24 size / 32 line height / 700 weight
        case large
        /// 28 size / 36 line height / 700 weight
        case extraLarge
    }
    static func heading(_ token: HeadingToken) -> FinancialConnectionsFont {
        let font: UIFont
        let lineHeight: CGFloat
        let appleTextStyle: UIFont.TextStyle
        switch token {
        case .medium:
            font = UIFont.systemFont(ofSize: 20, weight: .bold)
            lineHeight = 28
            appleTextStyle = .title3
        case .large:
            font = UIFont.systemFont(ofSize: 24, weight: .bold)
            lineHeight = 32
            appleTextStyle = .title2
        case .extraLarge:
            font = UIFont.systemFont(ofSize: 28, weight: .bold)
            lineHeight = 36
            appleTextStyle = .title1
        }
        return .create(font: font, lineHeight: lineHeight, appleTextStyle: appleTextStyle)
    }

    enum BodyToken {
        /// 12 size / 16 line height / 400 weight
        case extraSmall
        /// 12 size / 16 line height / 600 weight
        case extraSmallEmphasized
        /// 14 size / 20 line height / 400 weight
        case small
        /// 14 size / 20 line height / 600 weight
        case smallEmphasized
        /// 16 size / 24 line height / 400 weight
        case medium
        /// 16 size / 24 line height / 600 weight
        case mediumEmphasized
    }
    static func body(_ token: BodyToken) -> FinancialConnectionsFont {
        let font: UIFont
        let lineHeight: CGFloat
        let appleTextStyle: UIFont.TextStyle
        switch token {
        case .extraSmall:
            font = UIFont.systemFont(ofSize: 12, weight: .regular)
            lineHeight = 16
            appleTextStyle = .caption1
        case .extraSmallEmphasized:
            font = UIFont.systemFont(ofSize: 12, weight: .bold)
            lineHeight = 16
            appleTextStyle = .caption1
        case .small:
            font = UIFont.systemFont(ofSize: 14, weight: .regular)
            lineHeight = 20
            appleTextStyle = .footnote
        case .smallEmphasized:
            font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            lineHeight = 20
            appleTextStyle = .footnote
        case .medium:
            font = UIFont.systemFont(ofSize: 16, weight: .regular)
            lineHeight = 24
            appleTextStyle = .callout
        case .mediumEmphasized:
            font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            lineHeight = 24
            appleTextStyle = .callout
        }
        return .create(font: font, lineHeight: lineHeight, appleTextStyle: appleTextStyle)
    }

    enum LabelToken {
        /// 12 size / 16 line height / 400 weight
        case small
        /// 12 size / 16 line height / 600 weight
        case smallEmphasized
        /// 14 size / 20 line height / 400 weight
        case medium
        /// 14 size / 20 line height / 600 weight
        case mediumEmphasized
        /// 16 size / 24 line height / 400 weight
        case large
        /// 16 size / 24 line height / 600 weight
        case largeEmphasized
    }
    static func label(_ token: LabelToken) -> FinancialConnectionsFont {
        let font: UIFont
        let lineHeight: CGFloat
        let appleTextStyle: UIFont.TextStyle
        switch token {
        case .small:
            font = UIFont.systemFont(ofSize: 12, weight: .regular)
            lineHeight = 16
            appleTextStyle = .caption1
        case .smallEmphasized:
            font = UIFont.systemFont(ofSize: 12, weight: .semibold)
            lineHeight = 16
            appleTextStyle = .caption1
        case .medium:
            font = UIFont.systemFont(ofSize: 14, weight: .regular)
            lineHeight = 20
            appleTextStyle = .footnote
        case .mediumEmphasized:
            font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            lineHeight = 20
            appleTextStyle = .footnote
        case .large:
            font = UIFont.systemFont(ofSize: 16, weight: .regular)
            lineHeight = 24
            appleTextStyle = .callout
        case .largeEmphasized:
            font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            lineHeight = 24
            appleTextStyle = .callout
        }
        return .create(font: font, lineHeight: lineHeight, appleTextStyle: appleTextStyle)
    }

    enum CodeToken {
        /// 16 size / 24 line height / 600 weight
        case largeEmphasized
    }
    static func code(_ token: CodeToken) -> FinancialConnectionsFont {
        let font: UIFont
        let lineHeight: CGFloat
        let appleTextStyle: UIFont.TextStyle
        switch token {
        case .largeEmphasized:
            font = UIFont.monospacedSystemFont(ofSize: 16, weight: .semibold)
            lineHeight = 24
            appleTextStyle = .body
        }
        return .create(font: font, lineHeight: lineHeight, appleTextStyle: appleTextStyle)
    }

    private static func create(font: UIFont, lineHeight: CGFloat, appleTextStyle: UIFont.TextStyle) -> FinancialConnectionsFont {
        let scaledFont = scaleFont(font, appleTextStyle: appleTextStyle)
        return FinancialConnectionsFont(
            uiFont: scaledFont,
            lineHeight: scaleLineHeight(lineHeight, font: font, scaledFont: scaledFont)
        )
    }

    private static func scaleFont(_ font: UIFont, appleTextStyle: UIFont.TextStyle) -> UIFont {
        let metrics = UIFontMetrics(forTextStyle: appleTextStyle)
        let scaledFont = metrics.scaledFont(for: font)
        return scaledFont
    }

    private static func scaleLineHeight(_ lineHeight: CGFloat, font: UIFont, scaledFont: UIFont) -> CGFloat {
        return lineHeight * (scaledFont.pointSize / max(1, font.pointSize))
    }
}
