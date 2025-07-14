//
//  LinkSignUpBottomSheetContentWrapper.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 7/10/25.
//

import UIKit

final class LinkSignUpBottomSheetContentWrapper: UIViewController, BottomSheetContentViewController {
    private let contentViewController: UIViewController
    private let onDismiss: () -> Void

    lazy var navigationBar: SheetNavigationBar = {
        let navigationBar = LinkSheetNavigationBar(
            isTestMode: false,
            appearance: .init()
        )
        navigationBar.delegate = self
        return navigationBar
    }()

    var requiresFullScreen: Bool { true }

    init(contentViewController: UIViewController, onDismiss: @escaping () -> Void) {
        self.contentViewController = contentViewController
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(contentViewController)
        view.addSubview(contentViewController.view)
        contentViewController.didMove(toParent: self)

        contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            contentViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func didTapOrSwipeToDismiss() {
        onDismiss()
    }
}

// MARK: - SheetNavigationBarDelegate

extension LinkSignUpBottomSheetContentWrapper: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        didTapOrSwipeToDismiss()
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        didTapOrSwipeToDismiss()
    }
}
