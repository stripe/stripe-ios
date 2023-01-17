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
    public let style: Style
    public let theme: ElementsUITheme

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
        let theme: ElementsUITheme
        public init(elements: [UIView], bordered: Bool, theme: ElementsUITheme = .default) {
            self.elements = elements
            self.bordered = bordered
            self.theme = theme
        }
    }

    var viewModel: ViewModel {
        return ViewModel(elements: elements.map({ $0.view }), bordered: style == .bordered, theme: theme)
    }

    // MARK: - Initializer

    public convenience init(elements: [Element?], theme: ElementsUITheme = .default) {
        self.init(elements: elements, style: .plain, theme: theme)
    }

    public init(elements: [Element?], style: Style, theme: ElementsUITheme = .default) {
        self.elements = elements.compactMap { $0 }
        self.style = style
        self.theme = theme
        self.elements.forEach { $0.delegate = self }
    }

    public func setElements(_ elements: [Element], hidden: Bool, animated: Bool) {
        formView.setViews(elements.map({ $0.view }), hidden: hidden, animated: animated)
    }
}

// MARK: - Element

extension FormElement: Element {
    public var view: UIView {
        return formView
    }
}
