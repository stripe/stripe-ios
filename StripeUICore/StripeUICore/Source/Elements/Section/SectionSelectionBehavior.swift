//
//  SectionSelectionBehavior.swift
//  StripeUICore
//
//  Created by Mat Schmid on 5/27/25.
//

import UIKit

@_spi(STP) public enum SelectionBehavior {
    case `default`
    case highlightBorder(configuration: HighlightBorderConfiguration)
}

@_spi(STP) public struct HighlightBorderConfiguration {
    @_spi(STP) public let width: CGFloat
    @_spi(STP) public let color: UIColor
    @_spi(STP) public let animator: UIViewPropertyAnimator

    @_spi(STP) public init(width: CGFloat, color: UIColor, animator: UIViewPropertyAnimator) {
        self.width = width
        self.color = color
        self.animator = animator
    }
}
