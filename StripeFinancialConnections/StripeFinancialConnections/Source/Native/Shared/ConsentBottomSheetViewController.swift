//
//  ConsentBottomSheetViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/13/22.
//

import Foundation
import UIKit

final class ConsentBottomSheetViewController: UIViewController {

    private let model: ConsentBottomSheetModel
    private let didSelectURL: (URL) -> Void

    private var openContraint: NSLayoutConstraint?
    private var closeContraint: NSLayoutConstraint?

    init(
        model: ConsentBottomSheetModel,
        didSelectURL: @escaping (URL) -> Void
    ) {
        self.model = model
        self.didSelectURL = didSelectURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapBackground))
        tapGestureRecognizer.delegate = self
        view.addGestureRecognizer(tapGestureRecognizer)

        let dataAccessNoticeView = ConsentBottomSheetView(
            model: model,
            didSelectOK: { [weak self] in
                self?.dismiss(animated: true)
            },
            didSelectURL: didSelectURL
        )
        view.addSubview(dataAccessNoticeView)
        dataAccessNoticeView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dataAccessNoticeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dataAccessNoticeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        openContraint = dataAccessNoticeView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        closeContraint = dataAccessNoticeView.topAnchor.constraint(equalTo: view.bottomAnchor)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isBeingPresented {
            animateShowing(true)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed {
            animateShowing(false)
        }
    }

    // It is more better to do animations with custom UIViewController
    // animations but this is meant to be a quick implementation.
    private func animateShowing(_ isShowing: Bool) {
        let setInitialState = { [weak self] in
            self?.openContraint?.isActive = false
            self?.closeContraint?.isActive = true
            self?.view.layoutIfNeeded()
            self?.view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        }
        let setFinalState = { [weak self] in
            self?.closeContraint?.isActive = false
            self?.openContraint?.isActive = true
            self?.view.layoutIfNeeded()
            self?.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        }

        if isShowing {
            setInitialState()
        }

        UIView.animate(
            withDuration: 0.25,
            delay: 0.0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 0.5,
            options: [],
            animations: {
                if isShowing {
                    setFinalState()
                } else {
                    setInitialState()
                }
            }
        )
    }

    @objc private func didTapBackground() {
        dismiss(animated: true)
    }
}

// MARK: - <UIGestureRecognizerDelegate>

extension ConsentBottomSheetViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // only consider touches on the dark overlay area
        return touch.view === self.view
    }
}

// MARK: - Presenting

extension ConsentBottomSheetViewController {

    static func present(
        withModel model: ConsentBottomSheetModel,
        didSelectUrl: @escaping (URL) -> Void
    ) {
        let consentBottomSheetViewController = ConsentBottomSheetViewController(
            model: model,
            didSelectURL: didSelectUrl
        )
        consentBottomSheetViewController.modalTransitionStyle = .crossDissolve
        consentBottomSheetViewController.modalPresentationStyle = .overCurrentContext
        // `false` for animations because we do a custom animation inside VC logic
        UIViewController
            .topMostViewController()?
            .present(consentBottomSheetViewController, animated: false, completion: nil)
    }
}
