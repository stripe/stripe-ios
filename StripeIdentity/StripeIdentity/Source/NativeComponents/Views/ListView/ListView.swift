//
//  ListView.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 1/10/22.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

/**
 A reusable view that can display a short list of items.

 Note: If displaying a list with many items, use a `UITableView` instead to take
 advantage of cell reuse UI performance optimizations.
 */
final class ListView: UIView {

    struct Styling {
        static var font: UIFont {
            IdentityUI.preferredFont(forTextStyle: .body)
        }

        static let itemInsets = NSDirectionalEdgeInsets(top: 24, leading: 16, bottom: 24, trailing: 16)
        static let itemAccessibilitySpacing: CGFloat = 16
    }

    struct ViewModel {
        let items: [ListItemView.ViewModel]
    }

    // MARK: Properties

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.distribution = .fill
        stackView.alignment = .fill
        return stackView
    }()

    private var separatorViews: [UIView] = []
    private var itemViews: [ListItemView] = []

    // MARK: Init

    init() {
        super.init(frame: .zero)

        addAndPinSubview(stackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Configure

    func configure(with viewModel: ViewModel) {
        if viewModel.items.count != itemViews.count {
            rebuildViews(from: viewModel)
        }

        // Configure each item view
        zip(viewModel.items, itemViews).forEach { itemViewModel, itemView in
            itemView.configure(with: itemViewModel)
        }
    }

    // MARK: Accessibility

    /**
     Notifies the accessibility engine that there's been a layout change and
     focuses the VoiceOver onto the itemView with the specified index.

     - Parameter:
       - index: The index of the list item to focus on
     */
    func focusAccessibility(onItemIndex index: Int) {
        guard let itemView = itemViews.stp_boundSafeObject(at: index) else {
            return
        }
        UIAccessibility.post(notification: .layoutChanged, argument: itemView)
    }

    // MARK: Private

    private func rebuildViews(from viewModel: ViewModel) {
        // Remove old views
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        separatorViews = []
        itemViews = []

        // If there's no items to display, the view should be empty
        guard !viewModel.items.isEmpty else {
            return
        }

        // Reserve array capacity
        separatorViews.reserveCapacity(viewModel.items.count + 1)
        itemViews.reserveCapacity(viewModel.items.count)

        // Add top separator
        let firstSeparatorView = UIView()
        stackView.addArrangedSubview(firstSeparatorView)
        separatorViews.append(firstSeparatorView)

        // Add a view and separator for each item in the view model
        viewModel.items.forEach { itemViewModel in
            // Add item view
            let itemView = ListItemView()
            stackView.addArrangedSubview(itemView)
            itemViews.append(itemView)
            itemView.configure(with: itemViewModel)

            // Add separator
            let separatorView = UIView()
            stackView.addArrangedSubview(separatorView)
            separatorViews.append(separatorView)
        }

        // Configure separator color & height
        separatorViews.forEach { $0.backgroundColor = IdentityUI.separatorColor }
        NSLayoutConstraint.activate(
            separatorViews.map { $0.heightAnchor.constraint(equalToConstant: IdentityUI.separatorHeight) }
        )
    }
}


