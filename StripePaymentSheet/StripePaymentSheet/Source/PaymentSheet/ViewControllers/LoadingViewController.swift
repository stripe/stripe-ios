//
//  LoadingViewController.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 12/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

protocol LoadingViewControllerDelegate: AnyObject {
    func shouldDismiss(_ loadingViewController: LoadingViewController)
}

/// This just displays a spinner
/// For internal SDK use only
@objc(STP_Internal_LoadingViewController)
class LoadingViewController: UIViewController, BottomSheetContentViewController {

    enum Constants {
        static let defaultLoadingViewHeight: CGFloat = 244
    }

    lazy var navigationBar: SheetNavigationBar = {
        let navigationBar = SheetNavigationBar(isTestMode: isTestMode,
                                               appearance: appearance)
        navigationBar.delegate = self
        return navigationBar
    }()

    let appearance: PaymentSheet.Appearance
    let isTestMode: Bool

    var requiresFullScreen: Bool {
        return false
    }
    func didTapOrSwipeToDismiss() {
        delegate?.shouldDismiss(self)
    }
    let loadingViewHeight: CGFloat
    var panScrollable: UIScrollView?
    let activityIndicator = UIActivityIndicatorView(style: .medium)
    weak var delegate: LoadingViewControllerDelegate?

    init(delegate: LoadingViewControllerDelegate, appearance: PaymentSheet.Appearance, isTestMode: Bool, loadingViewHeight: CGFloat = Constants.defaultLoadingViewHeight) {
        self.delegate = delegate
        self.appearance = appearance
        self.isTestMode = isTestMode
        self.loadingViewHeight = loadingViewHeight
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        activityIndicator.color = appearance.colors.background.contrastingColor
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self], handler: { (self: Self, _: UITraitCollection) in
                self.activityIndicator.color = self.appearance.colors.background.contrastingColor
            })
        }
        [activityIndicator].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            view.heightAnchor.constraint(equalToConstant: loadingViewHeight),
        ])
        activityIndicator.startAnimating()
    }

#if !os(visionOS)
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #unavailable(iOS 17.0) {
            activityIndicator.color = appearance.colors.background.contrastingColor
        }
    }
#endif

}

extension LoadingViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        delegate?.shouldDismiss(self)
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {}
}
