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
            views: elements.filter { !($0.view is HiddenElement.HiddenView) }.map({ $0.view }), // filter out hidden views to prevent showing the separator
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

    let theme: ElementsAppearance

    // MARK: - ViewModel

    struct ViewModel {
        let views: [UIView]
        let title: String?
        let errorText: String?
        var subLabel: String?
        let theme: ElementsAppearance
    }

    // MARK: - Initializers

    public init(title: String? = nil, elements: [Element], theme: ElementsAppearance = .default) {
        self.title = title
        self.elements = elements
        self.theme = theme
        elements.forEach {
            $0.delegate = self
        }
    }

    public convenience init(_ element: Element, theme: ElementsAppearance = .default) {
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

// MARK: HiddenElement

extension SectionElement {
    /// A simple container element where the element's view is hidden
    /// Useful when an element is a part of a section but it's view is embeded into another element
    /// E.g. card brand drop down embedded into the PAN textfield
    /// - Note: `HiddenElement`'s are skipped by the `ContainerElement`'s auto advance logic
    @_spi(STP) public final class HiddenElement: ContainerElement {
        final class HiddenView: UIView {}

        weak public var delegate: ElementDelegate?
        public lazy var view: UIView = {
            return HiddenView(frame: .zero) // Hide the element's view
        }()
        public let elements: [Element]

        public init?(_ element: Element?) {
            guard let element = element else {
                return nil
            }
            self.elements = [element]
            element.delegate = self
        }
    }
}

// MARK: - DebugDescription
extension SectionElement {
    public var debugDescription: String {
        return "<\(type(of: self)): \(Unmanaged.passUnretained(self).toOpaque())>; title = \(title ?? "nil")" + subElementDebugDescription
    }
}
