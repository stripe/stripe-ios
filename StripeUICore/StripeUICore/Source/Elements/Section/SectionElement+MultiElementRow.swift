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
        lazy var multiElementRowView: SectionContainerView.MultiElementRowView = {
            return SectionContainerView.MultiElementRowView(views: elements.map { $0.view }, theme: theme)
        }()
        public var view: UIView {
            multiElementRowView
        }
        public var stackView: UIStackView {
            multiElementRowView.stackView
        }
        public let elements: [Element]
        public let theme: ElementsUITheme

        public init(_ elements: [Element], theme: ElementsUITheme = .default) {
            self.elements = elements
            self.theme = theme
            elements.forEach {
                $0.delegate = self
            }
        }
    }
}
