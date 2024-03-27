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

    private let content: BottomSheetContent

    init(
        content: BottomSheetContent
    ) throws {
        self.content = content
        super.init(nibName: nil, bundle: nil)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTap))
        tapGestureRecognizer.delegate = self
        view.addGestureRecognizer(tapGestureRecognizer)

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
        // Don't constraint topAnchor due to the for .pageSheet
        NSLayoutConstraint.activate([
            bottomSheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomSheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didTap() {
        dismiss(animated: true)
    }
}

// MARK: - <UIGestureRecognizerDelegate>

extension BottomSheetViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // only consider touches on the dark overlay area
        return touch.view === self.view
    }
}
