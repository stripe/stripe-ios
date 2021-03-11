//
//  STPCoreViewController.swift
//  Stripe
//
//  Created by Brian Dorfman on 1/6/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import UIKit

/// This is the base class for all Stripe view controllers. It is intended for use
/// only by Stripe classes, you should not subclass it yourself in your app.
/// It theming, back/cancel button management, and other shared logic for
/// Stripe view controllers.
public class STPCoreViewController: UIViewController {
    /// A convenience initializer; equivalent to calling `init(theme: STPTheme.defaultTheme)`.
    @objc
    public convenience init() {
        self.init(theme: STPTheme.defaultTheme)
    }

    /// Initializes a new view controller with the specified theme
    /// - Parameter theme: The theme to use to inform the view controller's visual appearance. - seealso: STPTheme
    @objc public required init(theme: STPTheme?) {
        super.init(nibName: nil, bundle: nil)
        commonInit(with: theme)
    }

    /// Passes through to the default UIViewController behavior for this initializer,
    /// and then also sets the default theme as in `init`
    @objc public required override init(
        nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?
    ) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit(with: STPTheme.defaultTheme)
    }

    /// Passes through to the default UIViewController behavior for this initializer,
    /// and then also sets the default theme as in `init`
    @objc public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit(with: STPTheme.defaultTheme)
    }

    private var _theme: STPTheme = STPTheme.defaultTheme
    @objc var theme: STPTheme {
        get {
            _theme
        }
        set(theme) {
            _theme = theme
            updateAppearance()
        }
    }
    @objc var cancelItem: UIBarButtonItem?

    /// All designated initializers funnel through this method to do their setup
    /// - Parameter theme: Initial theme for this view controller
    func commonInit(with theme: STPTheme?) {
        if let theme = theme {
            _theme = theme
        } else {
            _theme = .defaultTheme
        }

        if !useSystemBackButton() {
            cancelItem = UIBarButtonItem(
                barButtonSystemItem: .cancel,
                target: self,
                action: #selector(STPAddCardViewController.handleCancelTapped(_:)))
            cancelItem?.accessibilityIdentifier = "CoreViewControllerCancelIdentifier"

            stp_navigationItemProxy?.leftBarButtonItem = cancelItem
        }

        NotificationCenter.default.addObserver(
            self, selector: #selector(STPAddCardViewController.updateAppearance),
            name: UIContentSizeCategory.didChangeNotification, object: nil)
    }

    /// Called in viewDidLoad after doing base implementation, before
    /// calling updateAppearance
    func createAndSetupViews() {
        // do nothing
    }

    // These viewDidX() methods have significant code done
    // in the base class and super must be called if they are overidden
    /// :nodoc:
    @objc
    public override func viewDidLoad() {
        super.viewDidLoad()

        createAndSetupViews()
        updateAppearance()
    }
    /// :nodoc:
    @objc
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateAppearance()
    }
    /// :nodoc:
    @objc
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }

    /// Update views based on current STPTheme
    @objc func updateAppearance() {
        let navBarTheme = navigationController?.navigationBar.stp_theme ?? theme
        navigationItem.leftBarButtonItem?.stp_setTheme(navBarTheme)
        navigationItem.rightBarButtonItem?.stp_setTheme(navBarTheme)
        cancelItem?.stp_setTheme(navBarTheme)

        view.backgroundColor = theme.primaryBackgroundColor

        setNeedsStatusBarAppearanceUpdate()
    }

    /// :nodoc:
    @objc public override var preferredStatusBarStyle: UIStatusBarStyle {
        let navBarTheme = navigationController?.navigationBar.stp_theme ?? theme
        return STPColorUtils.colorIsBright(navBarTheme.secondaryBackgroundColor)
            ? .default
            : .lightContent
    }

    /// Called by the automatically-managed back/cancel button
    /// By default pops the top item off the navigation stack, or if we are the
    /// root of the navigation controller, dimisses presentation
    /// - Parameter sender: Sender of the target action, if applicable.
    @objc func handleCancelTapped(_ sender: Any?) {
        if stp_isAtRootOfNavigationController() {
            // if we're the root of the navigation controller, we've been presented modally.
            presentingViewController?.dismiss(animated: true)
        } else {
            // otherwise, we've been pushed onto the stack.
            navigationController?.popViewController(animated: true)
        }
    }

    /// If you override this and return YES, then your CoreVC implementation will not
    /// create and set up a cancel and instead just use the default
    /// UIViewController back button behavior.
    /// You won't receive calls to `handleCancelTapped` if this is YES.
    /// Defaults to NO.
    func useSystemBackButton() -> Bool {
        return false
    }
}
