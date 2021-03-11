//
//  BottomSheet3DS2ViewController.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 1/20/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

protocol BottomSheet3DS2ViewControllerDelegate: AnyObject {
    func bottomSheet3DS2ViewControllerDidCancel(
        _ bottomSheet3DS2ViewController: BottomSheet3DS2ViewController)
}

class BottomSheet3DS2ViewController: UIViewController {

    weak var delegate: BottomSheet3DS2ViewControllerDelegate? = nil

    lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar()
        navBar.setStyle(.back)
        navBar.delegate = self
        return navBar
    }()

    var isDismissable: Bool {
        return false
    }

    let challengeViewController: UIViewController

    required init(challengeViewController: UIViewController) {
        self.challengeViewController = challengeViewController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CompatibleColor.systemBackground
        addChild(challengeViewController)

        let headerLabel = PaymentSheetUI.makeHeaderLabel()
        headerLabel.text =
            STPThreeDSNavigationBarCustomization.defaultSettings().navigationBarCustomization
            .headerText
        view.addSubview(headerLabel)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false

        let challengeView: UIView! = challengeViewController.view
        view.addSubview(challengeView)
        challengeView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            view.layoutMarginsGuide.trailingAnchor.constraint(equalTo: headerLabel.trailingAnchor),
            headerLabel.topAnchor.constraint(equalTo: view.topAnchor),

            challengeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: challengeView.trailingAnchor),
            challengeView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor),
            view.bottomAnchor.constraint(equalTo: challengeView.bottomAnchor),
        ])
    }
}

// MARK: - BottomSheetContentViewController
/// :nodoc:
extension BottomSheet3DS2ViewController: BottomSheetContentViewController {
    var allowsDragToDismiss: Bool {
        return false
    }

    func didTapOrSwipeToDismiss() {
        // no-op
    }

    var requiresFullScreen: Bool {
        return true
    }
}

// MARK: - SheetNavigationBarDelegate
/// :nodoc:
extension BottomSheet3DS2ViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        delegate?.bottomSheet3DS2ViewControllerDidCancel(self)
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        delegate?.bottomSheet3DS2ViewControllerDidCancel(self)
    }
}
