//
//  SubtitleElement.swift
//  StripeUICore
//
//  Created by Nick Porter on 3/26/25.
//

import UIKit

@_spi(STP) public class SubtitleElement: Element {
    public let view: UIView
    public let collectsUserInput: Bool = false
    weak public var delegate: ElementDelegate?

    public init(view: UIView, isHorizontalMode: Bool) {
        guard !isHorizontalMode else {
            self.view = view
            return
        }

        // Create a container view with padding
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(view)

        let padding = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: containerView.topAnchor, constant: padding.top),
            view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: padding.left),
            view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -padding.right),
            view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -padding.bottom),
        ])

        self.view = containerView
    }
}
