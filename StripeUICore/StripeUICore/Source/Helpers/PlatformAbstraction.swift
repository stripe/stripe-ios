//
//  PlatformAbstraction.swift
//  StripeUICore
//
//  Created by Stripe SDK for macOS AppKit support.
//  Copyright © 2024 Stripe, Inc. All rights reserved.
//

#if canImport(UIKit) && !os(macOS)
import UIKit

// MARK: - UIKit Type Aliases
@_spi(STP) public typealias StripeView = UIView
@_spi(STP) public typealias StripeViewController = UIViewController
@_spi(STP) public typealias StripeWindow = UIWindow
@_spi(STP) public typealias StripeColor = UIColor
@_spi(STP) public typealias StripeFont = UIFont
@_spi(STP) public typealias StripeImage = UIImage
@_spi(STP) public typealias StripeApplication = UIApplication
@_spi(STP) public typealias StripeScreen = UIScreen
@_spi(STP) public typealias StripeButton = UIButton
@_spi(STP) public typealias StripeLabel = UILabel
@_spi(STP) public typealias StripeTextField = UITextField
@_spi(STP) public typealias StripeScrollView = UIScrollView
@_spi(STP) public typealias StripeStackView = UIStackView
@_spi(STP) public typealias StripeControl = UIControl
@_spi(STP) public typealias StripeGestureRecognizer = UIGestureRecognizer
@_spi(STP) public typealias StripeTapGestureRecognizer = UITapGestureRecognizer
@_spi(STP) public typealias StripePanGestureRecognizer = UIPanGestureRecognizer
@_spi(STP) public typealias StripeTableView = UITableView
@_spi(STP) public typealias StripeTableViewCell = UITableViewCell
@_spi(STP) public typealias StripeCollectionView = UICollectionView
@_spi(STP) public typealias StripeCollectionViewCell = UICollectionViewCell
@_spi(STP) public typealias StripeNavigationController = UINavigationController
@_spi(STP) public typealias StripeTabBarController = UITabBarController

#elseif canImport(AppKit) && os(macOS)
import AppKit

// MARK: - AppKit Type Aliases
@_spi(STP) public typealias StripeView = NSView
@_spi(STP) public typealias StripeViewController = NSViewController
@_spi(STP) public typealias StripeWindow = NSWindow
@_spi(STP) public typealias StripeColor = NSColor
@_spi(STP) public typealias StripeFont = NSFont
@_spi(STP) public typealias StripeImage = NSImage
@_spi(STP) public typealias StripeApplication = NSApplication
@_spi(STP) public typealias StripeScreen = NSScreen
@_spi(STP) public typealias StripeButton = NSButton
@_spi(STP) public typealias StripeLabel = NSTextField // NSTextField acts as label when not editable
@_spi(STP) public typealias StripeTextField = NSTextField
@_spi(STP) public typealias StripeScrollView = NSScrollView
@_spi(STP) public typealias StripeStackView = NSStackView
@_spi(STP) public typealias StripeControl = NSControl
@_spi(STP) public typealias StripeGestureRecognizer = NSGestureRecognizer
@_spi(STP) public typealias StripeTapGestureRecognizer = NSClickGestureRecognizer
@_spi(STP) public typealias StripePanGestureRecognizer = NSPanGestureRecognizer
@_spi(STP) public typealias StripeTableView = NSTableView
@_spi(STP) public typealias StripeTableViewCell = NSTableCellView
@_spi(STP) public typealias StripeCollectionView = NSCollectionView
@_spi(STP) public typealias StripeCollectionViewCell = NSCollectionViewItem
@_spi(STP) public typealias StripeNavigationController = NSViewController // AppKit doesn't have navigation controller
@_spi(STP) public typealias StripeTabBarController = NSTabViewController

#endif

// MARK: - Platform-specific Extensions and Helpers

@_spi(STP) public extension StripeView {
    #if canImport(UIKit) && !os(macOS)
    func addAndPinSubview(_ subview: StripeView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subview)
        NSLayoutConstraint.activate([
            subview.topAnchor.constraint(equalTo: topAnchor),
            subview.leadingAnchor.constraint(equalTo: leadingAnchor),
            subview.trailingAnchor.constraint(equalTo: trailingAnchor),
            subview.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func stripeAddSubview(_ subview: StripeView) {
        addSubview(subview)
    }
    
    func stripeRemoveFromSuperview() {
        removeFromSuperview()
    }
    
    var stripeBackgroundColor: StripeColor? {
        get { backgroundColor }
        set { backgroundColor = newValue }
    }
    
    #elseif canImport(AppKit) && os(macOS)
    func addAndPinSubview(_ subview: StripeView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subview)
        NSLayoutConstraint.activate([
            subview.topAnchor.constraint(equalTo: topAnchor),
            subview.leadingAnchor.constraint(equalTo: leadingAnchor),
            subview.trailingAnchor.constraint(equalTo: trailingAnchor),
            subview.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func stripeAddSubview(_ subview: StripeView) {
        addSubview(subview)
    }
    
    func stripeRemoveFromSuperview() {
        removeFromSuperview()
    }
    
    var stripeBackgroundColor: StripeColor? {
        get { 
            guard let cgColor = layer?.backgroundColor else { return nil }
            return NSColor(cgColor: cgColor)
        }
        set { 
            wantsLayer = true
            layer?.backgroundColor = newValue?.cgColor
        }
    }
    #endif
}

@_spi(STP) public extension StripeViewController {
    #if canImport(UIKit) && !os(macOS)
    var stripeView: StripeView { return view }
    
    func stripePresent(_ viewController: StripeViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        present(viewController, animated: animated, completion: completion)
    }
    
    func stripeDismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        dismiss(animated: animated, completion: completion)
    }
    
    #elseif canImport(AppKit) && os(macOS)
    var stripeView: StripeView { return view }
    
    func stripePresent(_ viewController: StripeViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        // AppKit modal presentation
        if let window = view.window {
            window.beginSheet(viewController.view.window ?? NSWindow()) { _ in
                completion?()
            }
        } else {
            // Fallback to window presentation
            let window = NSWindow()
            window.contentViewController = viewController
            window.makeKeyAndOrderFront(nil)
            completion?()
        }
    }
    
    func stripeDismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        if let window = view.window, let sheetParent = window.sheetParent {
            sheetParent.endSheet(window)
        } else {
            view.window?.close()
        }
        completion?()
    }
    #endif
}

// MARK: - Platform-specific Color Extensions
@_spi(STP) public extension StripeColor {
    #if canImport(UIKit) && !os(macOS)
    static var stripeSystemBackground: StripeColor {
        if #available(iOS 13.0, *) {
            return .systemBackground
        } else {
            return .white
        }
    }
    
    static var stripeLabel: StripeColor {
        if #available(iOS 13.0, *) {
            return .label
        } else {
            return .black
        }
    }
    
    #elseif canImport(AppKit) && os(macOS)
    static var stripeSystemBackground: StripeColor {
        if #available(macOS 10.14, *) {
            return .controlBackgroundColor
        } else {
            return .white
        }
    }
    
    static var stripeLabel: StripeColor {
        if #available(macOS 10.14, *) {
            return .labelColor
        } else {
            return .black
        }
    }
    #endif
}

// MARK: - Platform-specific Application Extensions
@_spi(STP) public extension StripeApplication {
    #if canImport(UIKit) && !os(macOS)
    static var stripeShared: StripeApplication { return .shared }
    
    var stripeKeyWindow: StripeWindow? {
        if #available(iOS 13.0, *) {
            return connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .first(where: { $0 is UIWindowScene })
                .flatMap({ ($0 as? UIWindowScene) })?.windows
                .first(where: \.isKeyWindow)
        } else {
            return keyWindow
        }
    }
    
    #elseif canImport(AppKit) && os(macOS)
    static var stripeShared: StripeApplication { return .shared }
    
    var stripeKeyWindow: StripeWindow? {
        return keyWindow
    }
    #endif
} 