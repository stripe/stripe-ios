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
        let setMask: Bool
        public lazy var view: UIView = {
            return SectionContainerView.MultiElementRowView(views: elements.map { $0.view }, theme: theme, setMask: setMask)
        }()
        public let elements: [Element]
        public let theme: ElementsAppearance

        public init(_ elements: [Element], theme: ElementsAppearance = .default, setMask: Bool = false) {
            self.elements = elements
            self.theme = theme
            self.setMask = setMask
            elements.forEach {
                $0.delegate = self
            }
        }
    }
}
