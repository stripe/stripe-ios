//
//  SectionElement+MultiElementRow.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 3/18/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

public extension SectionElement {
    /// A simple container element that displays its child elements in a horizontal stackview
    @_spi(STP) final class MultiElementRow: ContainerElement {
        weak public var delegate: ElementDelegate?
        public lazy var view: UIView = {
            return SectionContainerView.MultiElementRowView(views: elements.map { $0.view }, theme: theme)
        }()
        public let elements: [Element]
        public let theme: ElementsAppearance

        public init(_ elements: [Element], theme: ElementsAppearance) {
            self.elements = elements
            self.theme = theme
            elements.forEach {
                $0.delegate = self
            }
        }

        public func toggleElement(_ element: Element, shouldShow: Bool, animated: Bool = true) {
            guard let multiElementRowView = view as? SectionContainerView.MultiElementRowView else {
                return
            }

            multiElementRowView.toggleView(element.view, shouldShow: shouldShow, animated: animated)
        }
    }
}
