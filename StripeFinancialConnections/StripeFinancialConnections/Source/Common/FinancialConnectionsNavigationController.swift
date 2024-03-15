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
        appearance.backgroundColor = .customBackgroundColor
        appearance.shadowColor = .clear  // remove border
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance

        // change the back button color
        navigationBar.tintColor = UIColor.iconDefault
        navigationBar.isTranslucent = false
    }

    static func configureNavigationItemForNative(
        _ navigationItem: UINavigationItem?,
        closeItem: UIBarButtonItem,
        shouldHideStripeLogo: Bool,
        shouldLeftAlignStripeLogo: Bool
    ) {
        if !shouldHideStripeLogo {
            let stripeLogoView: UIView = {
                let stripeLogoImageView = UIImageView(
                    image: {
                        if shouldLeftAlignStripeLogo {
                            return Image
                                .stripe_logo
                                .makeImage(template: true)
                                .withInsets(UIEdgeInsets(top: 0, left: 3, bottom: 0, right: 0))
                        } else {
                            return Image
                                .stripe_logo
                                .makeImage(template: true)
                        }
                    }()
                )
                stripeLogoImageView.tintColor = UIColor.textActionPrimary
                stripeLogoImageView.contentMode = .scaleAspectFit
                stripeLogoImageView.sizeToFit()
                stripeLogoImageView.frame = CGRect(
                    x: 0,
                    y: 0,
                    width: stripeLogoImageView.bounds.width * (20 / max(1, stripeLogoImageView.bounds.height)),
                    height: 20
                )
                // If `titleView` is directly set to the `UIImageView`
                // we can't control the sizing...so we create a `containerView`
                // so we can control `UIImageView` sizing.
                let containerView = UIView()
                containerView.frame = stripeLogoImageView.bounds
                containerView.addSubview(stripeLogoImageView)

                stripeLogoImageView.center = containerView.center
                return containerView
            }()

            if shouldLeftAlignStripeLogo {
                navigationItem?.leftBarButtonItem = UIBarButtonItem(customView: stripeLogoView)
            } else {
                navigationItem?.titleView = stripeLogoView
            }
        }
        navigationItem?.backButtonTitle = ""
        navigationItem?.rightBarButtonItem = closeItem
    }
}
