//
//  FormElement.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/7/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/**
 The top-most, parent Element Element container.
 Displays its views in a vertical stack.
 Coordinates focus between its child Elements.
 */
@_spi(STP) public class FormElement: ContainerElement {
    weak public var delegate: ElementDelegate?
    lazy var formView: FormView = {
        return FormView(viewModel: viewModel)
    }()

    public let elements: [Element]
    public let customSpacing: [(Element, CGFloat)]
    public let style: Style
    public let theme: ElementsAppearance

    // MARK: - Style
    public enum Style {
        /// Default element styling in stack view
        case plain
        /// Form draws borders around each Element
        case bordered
    }

    // MARK: - ViewModel
    public struct ViewModel {
        let elements: [UIView]
        let bordered: Bool
        let theme: ElementsAppearance
        let customSpacing: [(UIView, CGFloat)]
        public init(elements: [UIView], bordered: Bool, theme: ElementsAppearance = .default, customSpacing: [(UIView, CGFloat)] = []) {
            self.elements = elements
            self.bordered = bordered
            self.theme = theme
            self.customSpacing = customSpacing
        }
    }

    var viewModel: ViewModel {
        // filter out hidden elements so they don't take up any space in the form
        return ViewModel(elements: elements.map({ $0.view }).filter({ !($0 is SectionElement.HiddenElement.HiddenView) }), bordered: style == .bordered, theme: theme, customSpacing: customSpacing.map({ ($0.0.view, $0.1) }))
    }

    // MARK: - Initializer

    /// Initialize a FormElement.
    /// - Parameters
    ///   - elements: The list of elements
    ///   - theme: The ElementsUITheme
    ///   - customSpacing: A list of Elements and a CGFloat of custom spacing to use after the element
    public convenience init(elements: [Element?], theme: ElementsAppearance = .default, customSpacing: [(Element, CGFloat)] = []) {
        self.init(elements: elements, style: .plain, theme: theme, customSpacing: customSpacing)
    }

    public init(elements: [Element?], style: Style, theme: ElementsAppearance = .default, customSpacing: [(Element, CGFloat)] = []) {
        self.elements = elements.compactMap { $0 }
        self.style = style
        self.theme = theme
        self.customSpacing = customSpacing
        self.elements.forEach { $0.delegate = self }
    }

    public func toggleElements(_ elements: [Element], hidden: Bool, animated: Bool) {
        formView.setViews(elements.map({ $0.view }), hidden: hidden, animated: animated)
    }
}

// MARK: - Element

extension FormElement: Element {
    public var view: UIView {
        return formView
    }
}
