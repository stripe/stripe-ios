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
@_spi(STP) public class SectionElement: ContainerElement {
    weak public var delegate: ElementDelegate?
    lazy var sectionView: SectionView = {
        isViewInitialized = true
        return SectionView(viewModel: viewModel)
    }()
    var isViewInitialized: Bool = false
    var viewModel: SectionViewModel {
        return ViewModel(
            views: elements.map({ $0.view }),
            title: title,
            errorText: errorText,
            subLabel: subLabel
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


    // MARK: - ViewModel
    
    struct ViewModel {
        let views: [UIView]
        let title: String?
        let errorText: String?
        var subLabel: String? = nil
    }

    // MARK: - Initializers
    
    public init(title: String? = nil, elements: [Element]) {
        self.title = title
        self.elements = elements
        
        defer {
            elements.forEach {
                $0.delegate = self
            }
        }
    }
    
    public convenience init(_ element: Element) {
        self.init(title: nil, elements: [element])
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
