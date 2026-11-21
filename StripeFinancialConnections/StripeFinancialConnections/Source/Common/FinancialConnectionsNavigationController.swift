//
//  FinancialConnectionsNavigationController.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/6/22.
//

@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

class FinancialConnectionsNavigationController: UINavigationController {

    // Swift 5.8 requires us to manually mark inits as unavailable as well:
    override public init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
    }

    override public init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // only currently set for native flow
    weak var analyticsClient: FinancialConnectionsAnalyticsClient?
    private var lastInteractivePopGestureRecognizerEndedDate: Date?
    private weak var lastShownViewController: UIViewController?

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        // disable the ability for a user to swipe down to dismiss
        // because we want to make a network call (and wait for it)
        // before a user can fully dismiss
        isModalInPresentation = true
        listenToInteractivePopGestureRecognizer()
        navigationBar.accessibilityIdentifier = "fc_navigation_bar"
    }

    private func logNavigationBackEvent(fromViewController: UIViewController, source: String) {
        guard let analyticsClient = analyticsClient else {
            assertionFailure("Expected `analyticsClient` (\(FinancialConnectionsAnalyticsClient.self)) to be set.")
            return
        }
        analyticsClient
            .log(
                // we use the same event name for both clicks and swipes to
                // simplify analytics logging (same event, different parameters)
                eventName: "click.nav_bar.back",
                parameters: [
                    "source": source,
                ],
                pane: FinancialConnectionsAnalyticsClient.paneFromViewController(fromViewController)
            )
    }
}

// MARK: - Track Swipe Back Analytics Events

extension FinancialConnectionsNavigationController: UINavigationControllerDelegate {

    private func listenToInteractivePopGestureRecognizer() {
        delegate = self
        assert(interactivePopGestureRecognizer != nil)
        interactivePopGestureRecognizer?.addTarget(self, action: #selector(interactivePopGestureRecognizerDidChange))
    }

    @objc private func interactivePopGestureRecognizerDidChange() {
        if interactivePopGestureRecognizer?.state == .ended {
            // As soon as user releases the "interactive pop" the gesture will
            // move to the `.ended` state. Note that this does NOT mean
            // that the user actually finished the pop gesture and
            // popped the view controller.
            lastInteractivePopGestureRecognizerEndedDate = Date()
        }
    }

    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        if let lastInteractivePopGestureRecognizerEndedDate = lastInteractivePopGestureRecognizerEndedDate,
            Date().timeIntervalSince(lastInteractivePopGestureRecognizerEndedDate) < 0.7,
            let lastShownViewController = lastShownViewController
        {
            // If user _recently_ ended the interactive pop gesture
            // AND navigation controller presented a new view controller
            // it's extremely likely that user popped a view controller
            // by using the swipe gesture.
            logNavigationBackEvent(fromViewController: lastShownViewController, source: "interactive_pop_gesture")
        }
        lastInteractivePopGestureRecognizerEndedDate = nil
        lastShownViewController = viewController
    }
}

// MARK: - Track Back Button Press Analytics Events

extension FinancialConnectionsNavigationController: UINavigationBarDelegate {

    // `UINavigationBarDelegate` methods "just work" on `UINavigationController`
    // without having to set any delegates
    func navigationBar(
        _ navigationBar: UINavigationBar,
        shouldPop item: UINavigationItem
    ) -> Bool {
        if let topViewController = topViewController {
            logNavigationBackEvent(fromViewController: topViewController, source: "navigation_bar_button")
        } else {
            assertionFailure(
                "Expected a `topViewConroller` to exist for \(FinancialConnectionsNavigationController.self)"
            )
        }
        return true
    }
}

// MARK: - `UINavigationController` Modifications

// The purpose of this extension is to consolidate in one place
// all the common changes to `UINavigationController`
extension FinancialConnectionsNavigationController {

    func configureAppearanceForNative() {
        // UIKit can expose the navigation controller's view above the navigation bar
        // during push transitions when presented as a sheet on physical devices.
        // Keep it opaque so the presentation controller's dimming view does not show through.
        view.backgroundColor = FinancialConnectionsAppearance.Colors.surfacePrimary

        let backButtonImage = Image
            .back_arrow
            .makeImage(template: false)
            .applyFinancialConnectionsBackButtonEdgeInsets()

        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.setBackIndicatorImage(backButtonImage, transitionMaskImage: backButtonImage)
        navBarAppearance.backgroundColor = FinancialConnectionsAppearance.Colors.surfacePrimary
        navBarAppearance.shadowColor = .clear  // remove border
        navigationBar.standardAppearance = navBarAppearance
        navigationBar.scrollEdgeAppearance = navBarAppearance
        navigationBar.compactAppearance = navBarAppearance

        // change the back button color
        navigationBar.tintColor = FinancialConnectionsAppearance.Colors.icon
        navigationBar.isTranslucent = false
    }

    static func configureNavigationItemForNative(
        _ navigationItem: UINavigationItem?,
        closeItem: UIBarButtonItem,
        shouldHideLogo: Bool,
        appearance: FinancialConnectionsAppearance
    ) {
        let iconHeight: CGFloat = 20
        let logoView: UIView = {
            guard !shouldHideLogo else {
                // When bar buttons move into the iPhone Duo's side column, a navigation bar without
                // a title collapses. Keep an empty title so the bar height doesn't change between panes.
                return UIView(frame: CGRect(x: 0, y: 0, width: 1, height: iconHeight))
            }

            let logoImage = FinancialConnectionsLogoImageView(appearance: appearance)
            logoImage.contentMode = .scaleAspectFit
            logoImage.sizeToFit()

            let logoImageViewWidth = logoImage.bounds.width * (iconHeight / max(1, logoImage.bounds.height))
            logoImage.frame = CGRect(
                x: 0,
                y: 0,
                width: logoImageViewWidth,
                height: iconHeight
            )
            // Use a container to preserve the logo's size when used as a title view.
            return SafeAreaCenteredTitleView(contentView: logoImage)
        }()
        navigationItem?.titleView = logoView
        navigationItem?.backButtonTitle = ""
        navigationItem?.rightBarButtonItem = closeItem
    }
}

/// Centers its content in the navigation bar's safe area instead of the full bar width, so the
/// logo stays centered over the pane content when a side column insets it (e.g. on iPhone Duo).
private final class SafeAreaCenteredTitleView: UIView {
    private let contentView: UIView

    init(contentView: UIView) {
        self.contentView = contentView
        super.init(frame: contentView.bounds)
        addSubview(contentView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        var centerX = bounds.midX
        if let navigationBar = enclosingNavigationBar {
            let safeAreaFrame = navigationBar.bounds.inset(by: navigationBar.safeAreaInsets)
            centerX = convert(CGPoint(x: safeAreaFrame.midX, y: 0), from: navigationBar).x
        }
        contentView.center = CGPoint(x: centerX, y: bounds.midY)
    }

    // This view usually lies inside the safe area, so its own insets don't change when the bar's
    // do. Re-center whenever UIKit moves it or it moves into a bar.
    override var frame: CGRect {
        didSet { setNeedsLayout() }
    }

    override var center: CGPoint {
        didSet { setNeedsLayout() }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        setNeedsLayout()
    }

    private var enclosingNavigationBar: UINavigationBar? {
        var view = superview
        while let currentView = view {
            if let navigationBar = currentView as? UINavigationBar {
                return navigationBar
            }
            view = currentView.superview
        }
        return nil
    }
}

private final class FinancialConnectionsLogoImageView: UIImageView {
    private let appearance: FinancialConnectionsAppearance

    init(appearance: FinancialConnectionsAppearance) {
        self.appearance = appearance
        super.init(frame: .zero)
        tintColor = appearance.logoTintColor
        updateImage()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateImage()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateImage()
    }

    private func updateImage() {
        image = appearance.logoImage(for: traitCollection.userInterfaceStyle)
    }
}
