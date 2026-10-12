//
//  LinkHostedSheet.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

/// A Link sheet that shows another Stripe SDK's content, so the screens that SDK presents around Link's
/// authentication share Link's container, header and close button.
@_spi(STP) public final class LinkHostedSheet {
    /// The margins Link's own screens keep around their content, for hosted content to match.
    @_spi(STP) public static var contentMargins: NSDirectionalEdgeInsets {
        LinkUI.contentMargins
    }

    private let sheetViewController: SheetViewController

    /// - Parameters:
    ///   - content: The view controller to show below Link's header. Its view sizes itself with Auto Layout.
    ///   - onClose: Called when the user taps the close button or the area above the sheet. The caller
    ///     dismisses the sheet.
    @_spi(STP) public init(content: UIViewController, onClose: @escaping () -> Void) {
        sheetViewController = SheetViewController(content: content, onClose: onClose)
    }

    @_spi(STP) public func present(from presentingViewController: UIViewController) {
        presentingViewController.presentAsBottomSheet(sheetViewController, appearance: LinkUI.appearance)
    }

    @_spi(STP) public func dismiss(completion: (() -> Void)? = nil) {
        guard sheetViewController.presentingViewController != nil else {
            completion?()
            return
        }
        sheetViewController.dismiss(animated: true, completion: completion)
    }
}

private extension LinkHostedSheet {
    final class SheetViewController: BottomSheetViewController {
        override var sheetCornerRadius: CGFloat? {
            LinkUI.largeCornerRadius
        }

        override var navigationBarHeight: CGFloat {
            LinkUI.navigationBarHeight
        }

        private let hostedContentViewController: ContentViewController

        init(content: UIViewController, onClose: @escaping () -> Void) {
            hostedContentViewController = ContentViewController(content: content, onClose: onClose)
            super.init(
                contentViewController: hostedContentViewController,
                appearance: LinkUI.appearance,
                isTestMode: false,
                didCancelNative3DS2: {}
            )
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        required init(
            contentViewController: any BottomSheetContentViewController,
            appearance: PaymentSheet.Appearance,
            isTestMode: Bool,
            didCancelNative3DS2: @escaping () -> Void
        ) {
            fatalError("init(contentViewController:appearance:isTestMode:didCancelNative3DS2:) has not been implemented")
        }

        override func didTapOrSwipeToDismiss() {
            hostedContentViewController.didTapOrSwipeToDismiss()
        }
    }

    final class ContentViewController: UIViewController, BottomSheetContentViewController, SheetNavigationBarDelegate {
        let requiresFullScreen = false

        lazy var navigationBar: SheetNavigationBar = {
            let navigationBar = LinkSheetNavigationBar(
                isTestMode: false,
                appearance: LinkUI.appearance,
                brand: .link,
                shouldLogPaymentSheetAnalyticsOnDismissal: false
            )
            navigationBar.setStyle(.close(showAdditionalButton: false))
            navigationBar.delegate = self
            return navigationBar
        }()

        private let content: UIViewController
        private let onClose: () -> Void

        init(content: UIViewController, onClose: @escaping () -> Void) {
            self.content = content
            self.onClose = onClose
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .linkSurfacePrimary
            addChild(content)
            view.addAndPinSubview(content.view)
            content.didMove(toParent: self)
        }

        func didTapOrSwipeToDismiss() {
            onClose()
        }

        func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
            onClose()
        }

        func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
            // The hosted content is a single screen with no navigation.
        }
    }
}
