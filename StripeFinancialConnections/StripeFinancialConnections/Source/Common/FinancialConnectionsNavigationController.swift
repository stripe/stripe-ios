//
//  FinancialConnectionsNavigationController.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/6/22.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
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
        let backButtonImage = Image
            .back_arrow
            .makeImage(template: false)
            .withAlignmentRectInsets(UIEdgeInsets(top: 0, left: -13, bottom: -2, right: 0))
        let appearance = UINavigationBarAppearance()
        appearance.setBackIndicatorImage(backButtonImage, transitionMaskImage: backButtonImage)
        appearance.backgroundColor = FinancialConnectionsAppearance.Colors.background
        appearance.shadowColor = .clear  // remove border
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance

        // change the back button color
        navigationBar.tintColor = FinancialConnectionsAppearance.Colors.icon
        navigationBar.isTranslucent = false
    }

    static func configureNavigationItemForNative(
        _ navigationItem: UINavigationItem?,
        closeItem: UIBarButtonItem,
        shouldHideLogo: Bool,
        appearance: FinancialConnectionsAppearance,
        isTestMode: Bool
    ) {
        let iconHeight: CGFloat = 20
        var testModeImageViewWidth: CGFloat = 0
        var logoImageViewWidth: CGFloat = 0

        let testModeBadgeView: UIImageView? = {
            guard isTestMode else { return nil }

            let testModeImage = UIImageView(image: Image.testmode.makeImage())
            testModeImage.contentMode = .scaleAspectFit
            testModeImage.sizeToFit()
            testModeImageViewWidth = testModeImage.bounds.width * (iconHeight / max(1, testModeImage.bounds.height))
            testModeImage.frame = CGRect(
                x: 0,
                y: 0,
                width: testModeImageViewWidth,
                height: iconHeight
            )
            return testModeImage
        }()

        let logoView: UIImageView? = {
            guard !shouldHideLogo else { return nil }

            let logoImage = UIImageView(image: appearance.logo.makeImage(template: true))
            logoImage.tintColor = appearance.colors.logo
            logoImage.contentMode = .scaleAspectFit
            logoImage.sizeToFit()

            logoImageViewWidth = logoImage.bounds.width * (iconHeight / max(1, logoImage.bounds.height))
            logoImage.frame = CGRect(
                x: 0,
                y: 0,
                width: logoImageViewWidth,
                height: iconHeight
            )
            return logoImage
        }()

        let spacing: CGFloat = 6
        let imageViews = [logoView, testModeBadgeView].compactMap { $0.self }
        let stackView = UIStackView(arrangedSubviews: imageViews)
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = spacing
        stackView.frame = CGRect(
            x: 0,
            y: 0,
            width: logoImageViewWidth + testModeImageViewWidth + spacing,
            height: iconHeight
        )

        // If `titleView` is directly set to the custom view
        // we can't control the sizing...so we create a `containerView`
        // so we can control its sizing.
        let containerView = UIView()
        containerView.frame = stackView.bounds
        containerView.addSubview(stackView)
        stackView.center = containerView.center

        navigationItem?.titleView = stackView
        navigationItem?.backButtonTitle = ""
        navigationItem?.rightBarButtonItem = closeItem
    }
}
