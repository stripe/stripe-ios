//
//  LoadingViewController.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 12/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

protocol LoadingViewControllerDelegate: AnyObject {
    func shouldDismiss(_ loadingViewController: LoadingViewController)
}

/// This just displays a spinner
class LoadingViewController: UIViewController, BottomSheetContentViewController {
    lazy var navigationBar: SheetNavigationBar = {
        let navigationBar = SheetNavigationBar()
        navigationBar.delegate = self
        return navigationBar
    }()

    var isDismissable: Bool = true

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

    init(delegate: LoadingViewControllerDelegate) {
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

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
