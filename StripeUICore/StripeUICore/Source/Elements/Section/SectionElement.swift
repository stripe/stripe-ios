//
//  SectionElement.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/6/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/**
 A simple container element with an optional title and an error, and draws a border around its elements.
 Chooses which of its sub-elements' errors to display.
 */
@_spi(STP) public final class SectionElement: ContainerElement {
    weak public var delegate: ElementDelegate?
    lazy var sectionView: SectionView = {
        isViewInitialized = true
        return SectionView(viewModel: viewModel)
    }()
    var isViewInitialized: Bool = false
    var errorText: String? {
        // Find the first element that's 1. invalid and 2. has a displayable error
        for element in elements {
            if case let .invalid(error, shouldDisplay) = element.validationState, shouldDisplay {
                return error.localizedDescription
            }
        }
        return nil
    }
    var viewModel: SectionViewModel {
        return ViewModel(
            views: elements.map({ $0.view }),
            title: title,
            errorText: errorText,
            subLabel: subLabel,
            theme: theme
        )
    }
    public var elements: [Element] {
        didSet {
            elements.forEach {
                $0.delegate = self
            }
            if isViewInitialized {
                sectionView.update(with: viewModel)
            }
            delegate?.didUpdate(element: self)
        }
    }
    let title: String?

    var subLabel: String? {
        elements.compactMap({ $0.subLabelText }).first
    }

    let theme: ElementsUITheme

    // MARK: - ViewModel

    struct ViewModel {
        let views: [UIView]
        let title: String?
        let errorText: String?
        var subLabel: String?
        let theme: ElementsUITheme
    }

    // MARK: - Initializers

    public init(title: String? = nil, elements: [Element], theme: ElementsUITheme = .default) {
        self.title = title
        self.elements = elements
        self.theme = theme
        elements.forEach {
            $0.delegate = self
        }
    }

    public convenience init(_ element: Element, theme: ElementsUITheme = .default) {
        self.init(title: nil, elements: [element], theme: theme)
    }
}

// MARK: - Element

extension SectionElement: Element {
    public var view: UIView {
        return sectionView
    }
}

// MARK: - ElementDelegate

extension SectionElement: ElementDelegate {
    public func didUpdate(element: Element) {
        // Glue: Update the view and our delegate
        if isViewInitialized {
            sectionView.update(with: viewModel)
        }
        delegate?.didUpdate(element: self)
    }
}
