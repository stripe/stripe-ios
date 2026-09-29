//
//  Typography.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/14/26.
//

import SwiftUI

/// A semantic font and target line height that scale together with Dynamic Type.
/// Names and values used in static symbols are supplied from Figma.
struct Typography {

    /// Heading/XLarge: 28-point semibold text with a 36-point target line height.
    static let headingExtraLarge = Typography(font: .systemFont(ofSize: 28, weight: .semibold), lineHeight: 36, relativeTo: .title)

    /// Body/XLarge: 18-point regular text with a 28-point target line height.
    static let bodyExtraLarge = Typography(font: .systemFont(ofSize: 18), lineHeight: 28, relativeTo: .body)

    /// Body/Large: 16-point regular text with a 24-point target line height.
    static let bodyLarge = Typography(font: .systemFont(ofSize: 16), lineHeight: 24, relativeTo: .body)

    /// Body/Large Emphasized: 16-point medium text with a 24-point target line height.
    static let bodyLargeEmphasized = Typography(font: .systemFont(ofSize: 16, weight: .medium), lineHeight: 24, relativeTo: .body)

    /// Body/Medium: 14-point regular text with a 20-point target line height.
    static let bodyMedium = Typography(font: .systemFont(ofSize: 14), lineHeight: 20, relativeTo: .subheadline)

    /// Body/Small: 12-point regular text with a 16-point target line height.
    static let bodySmall = Typography(font: .systemFont(ofSize: 12), lineHeight: 16, relativeTo: .caption)

    /// The base font before Dynamic Type scaling.
    let font: UIFont

    /// The target line height in points before Dynamic Type scaling.
    let lineHeight: CGFloat

    /// The text style whose Dynamic Type scaling curve applies to the font and target line height.
    let relativeTo: Font.TextStyle
}

extension View {

    /// Applies a semantic font and additional line spacing, scaled for Dynamic Type.
    /// - Parameter typography: The typography style to apply.
    /// - Returns: A view with the scaled font and spacing between lines.
    func typography(_ typography: Typography) -> some View {
        modifier(TypographyModifier(typography: typography))
    }
}

private struct TypographyModifier: ViewModifier {
    private let typography: Typography
    @ScaledMetric private var fontSize: CGFloat

    init(typography: Typography) {
        self.typography = typography
        _fontSize = ScaledMetric(wrappedValue: typography.font.pointSize, relativeTo: typography.relativeTo)
    }

    // MARK: - ViewModifier

    func body(content: Content) -> some View {
        let font = typography.font.withSize(fontSize)
        let targetLineHeight = typography.lineHeight * fontSize / typography.font.pointSize
        return content
            .font(Font(font))
            .lineSpacing(max(0, targetLineHeight - font.lineHeight))
    }
}
