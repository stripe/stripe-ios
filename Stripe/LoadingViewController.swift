//
//  LoadingViewController.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 12/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

protocol LoadingViewControllerDelegate: AnyObject {
    func shouldDismiss(_ loadingViewController: LoadingViewController)
}

/// This just displays a spinner
/// For internal SDK use only
@objc(STP_Internal_LoadingViewController)
class LoadingViewController: UIViewController, BottomSheetContentViewController {
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
    let loadingViewHeight: CGFloat = 244
    var panScrollable: UIScrollView?
    // Workaround to silence a warning in the Catalyst target
    #if targetEnvironment(macCatalyst)
    let activityIndicator = UIActivityIndicatorView(style: .medium)
    #else
    let activityIndicator = UIActivityIndicatorView(style: .gray)
    #endif
    weak var delegate: LoadingViewControllerDelegate?

    init(delegate: LoadingViewControllerDelegate, appearance: PaymentSheet.Appearance, isTestMode: Bool) {
        self.delegate = delegate
        self.appearance = appearance
        self.isTestMode = isTestMode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.color = appearance.colors.background.contrastingColor
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
}

extension LoadingViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        delegate?.shouldDismiss(self)
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {}
}
