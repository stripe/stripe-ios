//
//  SectionSelectionBehavior.swift
//  StripeUICore
//
//  Created by Mat Schmid on 5/27/25.
//

import UIKit

@_spi(InternalOnlyAPI) public enum SelectionBehavior {
    case `default`
    case highlightBorder(configuration: HighlightBorderConfiguration)
}

@_spi(InternalOnlyAPI) public struct HighlightBorderConfiguration {
    @_spi(InternalOnlyAPI) public let width: CGFloat
    @_spi(InternalOnlyAPI) public let cornerRadius: CGFloat
    @_spi(InternalOnlyAPI) public let color: UIColor
    @_spi(InternalOnlyAPI) public let animator: UIViewPropertyAnimator

    @_spi(InternalOnlyAPI) public init(width: CGFloat, cornerRadius: CGFloat, color: UIColor, animator: UIViewPropertyAnimator) {
        self.width = width
        self.cornerRadius = cornerRadius
        self.color = color
        self.animator = animator
    }
}
