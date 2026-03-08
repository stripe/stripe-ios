//
//  ModalPresentationWrapperViewController.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 12/22/22.
//

import UIKit

class ModalPresentationWrapperViewController: UIViewController {

    private static let dimmingAlpha: CGFloat = 0.3
    private static let dimmingAnimationDuration: TimeInterval = 0.2

    private weak var vc: UIViewController?
    private var didAnimateDimmingIn = false
    private var isDimmingFadingOut = false

    // MARK: - Init

    init(vc: UIViewController) {
        self.vc = vc
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        view.alpha = 0.0
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !didAnimateDimmingIn {
            didAnimateDimmingIn = true
            animateDimming(to: Self.dimmingAlpha)
        }

        if let vc = vc, presentedViewController == nil {
            self.present(vc, animated: true)
        }
    }

    func dismissWithFade(completion: (() -> Void)? = nil) {
        guard !isDimmingFadingOut else {
            dismiss(animated: false, completion: completion)
            return
        }
        isDimmingFadingOut = true
        animateDimming(to: 0.0) {
            self.dismiss(animated: false, completion: completion)
        }
    }

    func startFadeOutIfNeeded() {
        guard !isDimmingFadingOut else {
            return
        }
        isDimmingFadingOut = true
        animateDimming(to: 0.0)
    }

    private func animateDimming(to targetAlpha: CGFloat, completion: (() -> Void)? = nil) {
        UIView.animate(
            withDuration: Self.dimmingAnimationDuration,
            animations: {
                self.view.alpha = targetAlpha
            },
            completion: { _ in
                completion?()
            }
        )
    }

    // MARK: - Touch Handler

    @objc
    private func didTap() {
        dismissWithFade()
    }
}
