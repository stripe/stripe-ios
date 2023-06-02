//
//  CustomSheetViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 6/2/23.
//

import Foundation
import UIKit

final class CustomSheetCommunicationHelper {

    fileprivate var dismissSheetClosure: (() -> Void)?
    private var sheetDidDismissClosure: (() -> Void)?

    func dismissSheet(completionHandler: (() -> Void)? = nil) {
        sheetDidDismissClosure = completionHandler
        dismissSheetClosure?()
    }

    fileprivate func sheetDidDismiss() {
        sheetDidDismissClosure?()
    }
}

extension UIViewController {

    @available(iOSApplicationExtension, unavailable)
    func presentAsSheet(communicationHelper: CustomSheetCommunicationHelper) {
        PresentCustomSheet(
            type: .contentViewController(self),
            sheetCommunicationHelper: communicationHelper
        )
    }
}

private enum CustomSheetPresentationType {
    case contentView(UIView)
    case contentViewController(UIViewController)
}

@available(iOSApplicationExtension, unavailable)
private func PresentCustomSheet(
    type: CustomSheetPresentationType,
    sheetCommunicationHelper: CustomSheetCommunicationHelper
) {
    guard let topMostViewController = UIViewController.topMostViewController() else {
        assertionFailure("Expected to always find a top view controller.")
        return
    }

    // First present an invisible view controller over the full screen.
    // After, when we present a sheet over the invisible view controller,
    // the invisible view controller will give an appearance as if
    // the iOS standard sheet animation _does not_ visually modify
    // the view hierarchy with a "hierarchy/depth" animation.
    let invisibleViewController = InvisibleViewController()
    invisibleViewController.modalPresentationStyle = .overFullScreen
    topMostViewController.present(invisibleViewController, animated: false)

    let didDissmiss: () -> Void = { [weak invisibleViewController] in
        // when the sheet VC dismisses, so will the `invisibleViewController`
        invisibleViewController?.dismiss(
            animated: false,
            completion: {
                sheetCommunicationHelper.sheetDidDismiss()
            }
        )
    }

    let customSheetViewController: CustomSheetViewController
    switch type {
    case .contentViewController(let contentViewController):
        customSheetViewController = CustomSheetViewController(
           contentViewController: contentViewController,
           didDismiss: didDissmiss
       )
    case .contentView(let contentView):
        customSheetViewController = CustomSheetViewController(
           contentView: contentView,
           didDismiss: didDissmiss
       )
    }
    sheetCommunicationHelper.dismissSheetClosure = { [weak customSheetViewController] in
        customSheetViewController?.dismiss(animated: true)
    }
    invisibleViewController.present(customSheetViewController, animated: true)
}

// TODO(kgaidis): for iOS 13, we may need to improve sheet background
@available(iOSApplicationExtension, unavailable)
private final class CustomSheetViewController: UIViewController, UIGestureRecognizerDelegate {

    private let contentView: UIView
    // optional because we may want to present a `contentView`
    // without a backing UIViewController
    private let contentViewController: UIViewController?
    private let didDismiss: () -> Void

    init(
        contentView: UIView,
        didDismiss: @escaping () -> Void
    ) {
        self.contentView = contentView
        self.contentViewController = nil
        self.didDismiss = didDismiss
        super.init(nibName: nil, bundle: nil)
    }

    init(
        contentViewController: UIViewController,
        didDismiss: @escaping () -> Void
    ) {
        self.contentView = contentViewController.view
        self.contentViewController = contentViewController
        self.didDismiss = didDismiss
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.layer.shadowOpacity = 0

        if let contentViewController = contentViewController {
            addChild(contentViewController)
        }
        view.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 0),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        if let contentViewController = contentViewController {
            contentViewController.didMove(toParent: self)
        }

        // modify `contentView` to fit what a custom sheet should look like
        contentView.layer.cornerRadius = 24
        contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        contentView.clipsToBounds = true
        contentView.backgroundColor = .customBackgroundColor

        // if the `contentView` is smaller than the total sheet height,
        // we want to enable dismiss-on-tap-of-dark-area
        let darkAreaTapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(didTapDarkArea)
        )
        darkAreaTapGestureRecognizer.delegate = self
        view.addGestureRecognizer(darkAreaTapGestureRecognizer)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed {
            didDismiss()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Handle

    @objc private func didTapDarkArea(_ tapGestureRecognizer: UITapGestureRecognizer) {
        dismiss(animated: true)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        let touchPoint = touch.location(in: self.view)
        if contentView.frame.contains(touchPoint) {
            // ignore the touch if it intersects with the `contentView`
            return false
        } else {
            return true
        }
    }
}

private class InvisibleViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        // just in case this view controller lingers around (due to a bug),
        // we also add this tap gesture recognizer to ensure user can
        // dismiss it
        let tapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(didTapView)
        )
        view.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc private func didTapView() {
        dismiss(animated: false)
    }
}
