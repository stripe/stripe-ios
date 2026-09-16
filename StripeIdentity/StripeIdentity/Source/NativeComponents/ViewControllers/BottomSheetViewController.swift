//
//  BottomSheetViewController.swift
//  StripeIdentity
//
//  Created by Chen Cen on 9/14/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

struct BottomSheetError: AnalyticLoggableStringErrorV2 {
    let loggableType: String
}

final class BottomSheetViewController: UIViewController {

    typealias BottomSheetContent = StripeAPI.VerificationPageStaticContentBottomSheetContent

    private static let contentDetentIdentifier = UISheetPresentationController.Detent.Identifier(
        "StripeIdentity.content"
    )

    private(set) var preferredDetentHeight: CGFloat = 0

    static func makeForPresentation(
        content: BottomSheetContent
    ) throws -> BottomSheetViewController {
        let viewController = try BottomSheetViewController(content: content)
        viewController.modalTransitionStyle = .coverVertical
        viewController.modalPresentationStyle = .pageSheet

        if #available(iOS 16.0, *) {
            let contentDetent = UISheetPresentationController.Detent.custom(
                identifier: contentDetentIdentifier
            ) { [weak viewController] context in
                min(viewController?.preferredDetentHeight ?? context.maximumDetentValue, context.maximumDetentValue)
            }
            viewController.sheetPresentationController?.detents = [contentDetent]
            viewController.sheetPresentationController?.selectedDetentIdentifier = contentDetentIdentifier
        } else {
            viewController.sheetPresentationController?.detents = [.medium(), .large()]
            viewController.sheetPresentationController?.selectedDetentIdentifier = .medium
        }

        return viewController
    }

    init(
        content: BottomSheetContent
    ) throws {
        super.init(nibName: nil, bundle: nil)

        view.backgroundColor = IdentityUI.identityElementsUITheme.colors.componentBackground

        let bottomSheetView: BottomSheetView
        bottomSheetView = try BottomSheetView(
            content: content
        ) { [weak self] in
            self?.dismiss(animated: true)
        } didOpenURL: { [weak self] url in
            self?.openInSafariViewController(url: url)
        }

        view.addSubview(bottomSheetView)
        bottomSheetView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bottomSheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomSheetView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            bottomSheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        view.layoutIfNeeded()
        preferredDetentHeight = bottomSheetView.calculateContentHeight()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
