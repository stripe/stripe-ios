//
//  LinkNavigationController.swift
//  StripePaymentSheet
//
//  Created by AI Assistant on 1/1/24.
//  Copyright © 2024 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

/// Protocol for headers that can be used with LinkNavigationController
protocol LinkNavigationHeader: UIView {
    /// Update the header to show or hide the back button
    func setShowsBackButton(_ showsBackButton: Bool, animated: Bool)
}

/// Base navigation controller with fixed header for Link flows
///
/// Features:
/// - Fixed header that remains visible during navigation
/// - Dynamic back button that appears when content is pushed
/// - Content area for pushable view controllers
/// - UINavigationController-style slide animations for push/pop transitions
///
/// Usage:
/// ```
/// class MyViewController: LinkNavigationController<MyHeader> {
///     override func createHeader() -> MyHeader {
///         return MyHeader()
///     }
///
///     override func setupInitialContent() {
///         // Setup your initial content view
///     }
/// }
/// ```
class LinkNavigationController<HeaderType: LinkNavigationHeader>: UIViewController {

    // MARK: - Abstract properties and methods

    /// Override this to create and configure your specific header
    func createHeader() -> HeaderType {
        fatalError("Subclasses must override createHeader()")
    }

    /// Override this to setup your initial content view
    func setupInitialContent() {
        fatalError("Subclasses must override setupInitialContent()")
    }

    /// Override this to setup initial content positioned off-screen for animations
    func setupInitialContentOffScreen() {
        fatalError("Subclasses must override setupInitialContentOffScreen()")
    }

    // MARK: - Fixed Header

    private lazy var headerContainerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        containerView.translatesAutoresizingMaskIntoConstraints = false
        return containerView
    }()

    private(set) lazy var fixedHeader: HeaderType = {
        let header = createHeader()
        header.translatesAutoresizingMaskIntoConstraints = false
        return header
    }()

    private(set) lazy var contentContainer: UIView = {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        return containerView
    }()

    // MARK: - Navigation Properties

    private var contentStack: [UIViewController] = [] {
        didSet {
            updateHeaderState()
        }
    }

    /// Whether the header should be shown (can be overridden by subclasses)
    var shouldShowHeader: Bool {
        return true
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.tintColor = .linkIconBrand
        view.backgroundColor = .systemBackground

        setupFixedHeaderLayout()
        setupInitialContent()
    }

    // MARK: - Layout

    private func setupFixedHeaderLayout() {
        // Add header container first
        view.addSubview(headerContainerView)
        headerContainerView.addSubview(fixedHeader)

        // Add content container
        view.addSubview(contentContainer)

        NSLayoutConstraint.activate([
            // Header container
            headerContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerContainerView.heightAnchor.constraint(equalToConstant: LinkUI.navigationBarHeight),

            // Fixed header within container
            fixedHeader.topAnchor.constraint(equalTo: headerContainerView.topAnchor, constant: LinkUI.contentMargins.top),
            fixedHeader.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor, constant: LinkUI.contentMargins.leading),
            fixedHeader.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor, constant: -LinkUI.contentMargins.trailing),
            fixedHeader.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor, constant: -LinkUI.contentMargins.bottom),

            // Content container
            contentContainer.topAnchor.constraint(equalTo: shouldShowHeader ? headerContainerView.bottomAnchor : view.topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // Show/hide header based on subclass preference
        headerContainerView.isHidden = !shouldShowHeader
    }

    // MARK: - Navigation Methods

    /// Updates the header state based on the content stack
    private func updateHeaderState(animated: Bool = true) {
        let shouldShowBackButton = !contentStack.isEmpty
        fixedHeader.setShowsBackButton(shouldShowBackButton, animated: animated)
    }

    /// Push a new view controller to the content area while keeping the header fixed
    func pushViewController(_ viewController: UIViewController, animated: Bool = true) {
        let currentViewController = contentStack.last
        let isInitialPush = currentViewController == nil

        // Add to our content stack
        contentStack.append(viewController)

        // Add new view controller as child
        addChild(viewController)
        contentContainer.addSubview(viewController.view)

        viewController.view.translatesAutoresizingMaskIntoConstraints = false

        // Set up constraints for the new view controller
        let leadingConstraint = viewController.view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor)
        let trailingConstraint = viewController.view.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor)
        let topConstraint = viewController.view.topAnchor.constraint(equalTo: contentContainer.topAnchor)
        let bottomConstraint = viewController.view.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)

        NSLayoutConstraint.activate([
            topConstraint,
            bottomConstraint,
            leadingConstraint,
            trailingConstraint,
        ])

        if animated {
            // Position new view controller off-screen to the right
            viewController.view.transform = CGAffineTransform(translationX: contentContainer.bounds.width, y: 0)

            // Ensure layout is updated before animation
            contentContainer.layoutIfNeeded()

            // Animate the transition
            UIView.animate(
                withDuration: 0.35,
                delay: 0,
                usingSpringWithDamping: 0.9,
                initialSpringVelocity: 0,
                options: [.allowUserInteraction, .curveEaseOut],
                animations: {
                    // Slide new view controller in from right
                    viewController.view.transform = .identity

                    // Slide current content out to the left
                    if let currentVC = currentViewController {
                        currentVC.view.transform = CGAffineTransform(translationX: -self.contentContainer.bounds.width, y: 0)
                    } else if isInitialPush {
                        // Let subclass handle sliding out initial content
                        self.animateInitialContentOut()
                    }
                },
                completion: { _ in
                    // Clean up the previous view
                    if let currentVC = currentViewController {
                        currentVC.view.removeFromSuperview()
                        currentVC.view.transform = .identity // Reset transform
                    } else if isInitialPush {
                        self.removeInitialContent()
                    }

                    viewController.didMove(toParent: self)
                }
            )
        } else {
            // Remove current content immediately without animation
            if let currentVC = currentViewController {
                currentVC.view.removeFromSuperview()
            } else if isInitialPush {
                removeInitialContent()
            }

            viewController.didMove(toParent: self)
        }

        // Update header to show back button
        updateHeaderState(animated: animated)
    }

    /// Pop the current view controller and return to the previous one
    @discardableResult
    func popViewController(animated: Bool = true) -> UIViewController? {
        guard let currentViewController = contentStack.popLast() else { return nil }

        let previousViewController = contentStack.last
        let returningToRoot = previousViewController == nil

        if animated {
            // Prepare the previous view or root view
            if let previousVC = previousViewController {
                // Re-add previous view controller positioned off-screen to the left
                contentContainer.addSubview(previousVC.view)
                previousVC.view.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    previousVC.view.topAnchor.constraint(equalTo: contentContainer.topAnchor),
                    previousVC.view.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
                    previousVC.view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
                    previousVC.view.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
                ])
                previousVC.view.transform = CGAffineTransform(translationX: -contentContainer.bounds.width, y: 0)
            } else if returningToRoot {
                // Re-add initial content positioned off-screen to the left
                setupInitialContentOffScreen()
            }

            // Ensure layout is updated before animation
            contentContainer.layoutIfNeeded()

            // Animate the transition
            UIView.animate(
                withDuration: 0.35,
                delay: 0,
                usingSpringWithDamping: 0.9,
                initialSpringVelocity: 0,
                options: [.allowUserInteraction, .curveEaseOut],
                animations: {
                    // Slide current view controller out to the right
                    currentViewController.view.transform = CGAffineTransform(translationX: self.contentContainer.bounds.width, y: 0)

                    // Slide previous content in from the left
                    if let previousVC = previousViewController {
                        previousVC.view.transform = .identity
                    } else if returningToRoot {
                        self.animateInitialContentIn()
                    }
                },
                completion: { _ in
                    // Remove current view controller
                    currentViewController.willMove(toParent: nil)
                    currentViewController.view.removeFromSuperview()
                    currentViewController.removeFromParent()
                    currentViewController.view.transform = .identity // Reset transform
                }
            )
        } else {
            // Remove current view controller immediately
            currentViewController.willMove(toParent: nil)
            currentViewController.view.removeFromSuperview()
            currentViewController.removeFromParent()

            // Show previous view controller or default verification view
            if let previousVC = previousViewController {
                contentContainer.addSubview(previousVC.view)
                previousVC.view.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    previousVC.view.topAnchor.constraint(equalTo: contentContainer.topAnchor),
                    previousVC.view.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
                    previousVC.view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
                    previousVC.view.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
                ])
            } else {
                setupInitialContent()
            }
        }

        // Update header state
        updateHeaderState(animated: animated)

        return currentViewController
    }

    /// Pop to the root (initial) view controller
    @discardableResult
    func popToRootViewController(animated: Bool = true) -> [UIViewController]? {
        let poppedViewControllers = Array(contentStack)
        guard !poppedViewControllers.isEmpty else { return nil }

        let currentViewController = contentStack.last

        if animated && currentViewController != nil {
            // Setup root view off-screen
            setupInitialContentOffScreen()
            contentContainer.layoutIfNeeded()

            // Animate transition
            UIView.animate(
                withDuration: 0.35,
                delay: 0,
                usingSpringWithDamping: 0.9,
                initialSpringVelocity: 0,
                options: [.allowUserInteraction, .curveEaseOut],
                animations: {
                    // Slide current view out to the right
                    currentViewController?.view.transform = CGAffineTransform(translationX: self.contentContainer.bounds.width, y: 0)

                    // Slide root view in from the left
                    self.animateInitialContentIn()
                },
                completion: { _ in
                    // Remove all pushed view controllers
                    for viewController in poppedViewControllers {
                        viewController.willMove(toParent: nil)
                        viewController.view.removeFromSuperview()
                        viewController.removeFromParent()
                        viewController.view.transform = .identity // Reset transform
                    }
                }
            )
        } else {
            // Remove all pushed view controllers immediately
            for viewController in poppedViewControllers {
                viewController.willMove(toParent: nil)
                viewController.view.removeFromSuperview()
                viewController.removeFromParent()
            }

            // Return to the original initial content
            setupInitialContent()
        }

        contentStack.removeAll()

        // Update header to hide back button
        updateHeaderState(animated: animated)

        return poppedViewControllers
    }

    // MARK: - Animation Helpers (to be overridden by subclasses)

    /// Override to define how initial content animates out during push
    func animateInitialContentOut() {
        // Default implementation - subclasses should override
    }

    /// Override to define how initial content animates in during pop
    func animateInitialContentIn() {
        // Default implementation - subclasses should override
    }

    /// Override to define how to remove initial content after animation
    func removeInitialContent() {
        // Default implementation - subclasses should override
    }

    // MARK: - Public Properties

    /// Current navigation stack count
    var navigationStackCount: Int {
        return contentStack.count
    }

    /// Whether we're currently at the root level
    var isAtRoot: Bool {
        return contentStack.isEmpty
    }
}
