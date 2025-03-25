//
//  StaticElement.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/18/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

/**
 A inert wrapper around a view.
 */
@_spi(STP) public class StaticElement: Element {
    public let collectsUserInput: Bool = false
    weak public var delegate: ElementDelegate?
    public let view: UIView
    public var isHidden: Bool = false {
        didSet {
            view.isHidden = isHidden
        }
    }

    public init(view: UIView, padding: UIEdgeInsets = .zero) {
        guard padding != .zero else {
            self.view = view
            return
        }

        // Create a container view with padding
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(view)

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: containerView.topAnchor, constant: padding.top),
            view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: padding.left),
            view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -padding.right),
            view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -padding.bottom),
        ])

        self.view = containerView
    }
}
