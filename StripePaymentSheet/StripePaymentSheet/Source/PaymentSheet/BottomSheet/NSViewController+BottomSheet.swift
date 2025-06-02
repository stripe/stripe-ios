//
//  NSViewController+BottomSheet.swift
//  StripePaymentSheet
//
//  Copyright © 2024 Stripe, Inc. All rights reserved.
//

#if canImport(AppKit) && os(macOS)
import AppKit
@_spi(STP) import StripeCore

extension NSViewController {
    /// Convenience method that presents the view controller in a custom sheet style for macOS
    func presentAsBottomSheet(
        _ viewControllerToPresent: SheetPresentable,
        appearance: PaymentSheet.Appearance,
        completion: (() -> Void)? = nil
    ) {
        // For macOS, we use the native sheet presentation
        presentAsSheet(viewControllerToPresent, completion: completion)
    }
}

/// AppKit version of BottomSheetPresentable protocol
protocol SheetPresentable: NSViewController {
    /// Called when the user dismisses the sheet
    func didTapOrSwipeToDismiss()
}

/// AppKit-compatible sheet presentation delegate
@objc(STPSheetTransitioningDelegate)
class SheetTransitioningDelegate: NSObject {
    
    static var appearance: PaymentSheet.Appearance = PaymentSheet.Appearance.default
    
    /**
     Returns an instance of the delegate, retained for the duration of presentation
     */
    static var `default`: SheetTransitioningDelegate = {
        return SheetTransitioningDelegate()
    }()
}

/// AppKit version of BottomSheetViewController
/// For internal SDK use only
@objc(STP_Internal_SheetViewController)
class SheetViewController: NSViewController {
    
    struct Constants {
        static let keyboardAvoidanceEdgePadding: CGFloat = 16
    }

    // MARK: - Views
    lazy var scrollView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        return scrollView
    }()

    private lazy var navigationBarContainerView: NSStackView = {
        let stackView = NSStackView()
        stackView.orientation = .vertical
        return stackView
    }()

    private lazy var contentContainerView: NSStackView = {
        let stackView = NSStackView()
        stackView.orientation = .vertical
        return stackView
    }()

    private(set) var contentStack: [SheetContentViewController] = []

    var contentViewController: SheetContentViewController {
        return contentStack.first!
    }

    var contentRequiresFullScreen: Bool {
        return contentViewController.requiresFullScreen
    }

    func setViewControllers(_ viewControllers: [SheetContentViewController]) {
        contentStack = viewControllers
        if let top = viewControllers.first {
            updateContent(to: top)
        }
    }

    func pushContentViewController(_ contentViewController: SheetContentViewController) {
        contentStack.insert(contentViewController, at: 0)
        updateContent(to: contentViewController)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // Set up the scroll view
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Create document view for scroll view
        let documentView = NSView()
        scrollView.documentView = documentView
        
        // Add content container to document view
        documentView.addSubview(contentContainerView)
        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            contentContainerView.topAnchor.constraint(equalTo: documentView.topAnchor),
            contentContainerView.leadingAnchor.constraint(equalTo: documentView.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: documentView.trailingAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: documentView.bottomAnchor),
            contentContainerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    private func updateContent(to contentViewController: SheetContentViewController) {
        // Remove existing content
        contentContainerView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add navigation bar if present
        contentContainerView.addArrangedSubview(contentViewController.navigationBar)
        
        // Add the content view controller
        addChild(contentViewController)
        contentContainerView.addArrangedSubview(contentViewController.view)
        contentViewController.didMove(toParent: self)
    }
}

/// AppKit content view controller protocol
protocol SheetContentViewController: NSViewController {
    var navigationBar: NSView { get } // Simplified for AppKit
    var requiresFullScreen: Bool { get }
    func didTapOrSwipeToDismiss()
}

extension SheetViewController: SheetPresentable {
    func didTapOrSwipeToDismiss() {
        contentViewController.didTapOrSwipeToDismiss()
    }
}

#endif 