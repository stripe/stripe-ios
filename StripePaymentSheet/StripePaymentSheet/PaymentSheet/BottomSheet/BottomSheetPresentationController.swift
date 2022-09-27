//
//  BottomSheetPresentationController.swift
//  StripeiOS
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeUICore

/// The BottomSheetPresentationController is the middle layer between the presentingViewController
/// and the presentedViewController.
///
/// It does a few things:
/// - adds a background overlay between the presenting & presented
/// - Tells the presented view controller when the background view is tapped
/// - Pins the presented view controller to the bottom of the screen, but doesn't constrain the height (unless `forceFullHeight` is `true`)
@objc(STPBottomSheetPresentationController)
class BottomSheetPresentationController: UIPresentationController {
    // MARK: - Properties
    private var bottomAnchor: NSLayoutConstraint?
    private var presentable: BottomSheetPresentable? {
        return presentedViewController as? BottomSheetPresentable
    }
    private lazy var fullHeightConstraint: NSLayoutConstraint = {
        guard let containerView = containerView else {
            assertionFailure()
            return NSLayoutConstraint()
        }
        return presentedView.topAnchor.constraint(
            equalTo: containerView.safeAreaLayoutGuide.topAnchor)
    }()
    
    var forceFullHeight: Bool = false {
        didSet {
            guard containerView != nil else {
                // This can happen if we try setting content before
                // the presentation animation has run (happens sometimes
                // with really fast internet and automated tests)
                // fullHeightConstraint will get updated
                // when view is added
                return
            }
            fullHeightConstraint.isActive = forceFullHeight
        }
    }
    
    // MARK: - Views
    
    /**
     Background view used as an overlay over the presenting view
     */
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.alpha = 0
        view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapBackgroundView))
        view.addGestureRecognizer(tap)
        return view
    }()
    
    /**
     Override presented view to return non-optional
     */
    override var presentedView: UIView {
        return presentedViewController.view
    }
    
    // MARK: - Lifecycle
    
    override func presentationTransitionWillBegin() {
        installConstraints()
        
        guard let coordinator = presentedViewController.transitionCoordinator else {
            backgroundView.alpha = 1
            return
        }
        
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.backgroundView.alpha = 1
            self?.presentedViewController.setNeedsStatusBarAppearanceUpdate()
        })
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        guard !completed else { return }
        
        backgroundView.removeFromSuperview()
    }
    
    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            backgroundView.alpha = 0
            return
        }
        
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.backgroundView.alpha = 0
            self?.presentingViewController.setNeedsStatusBarAppearanceUpdate()
        })
    }
    
    /**
     Update presented view size in response to size class changes
     */
    override func viewWillTransition(
        to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard
                let self = self
            else { return }
            
            self.addRoundedCorners(to: self.presentedView)
        })
    }
    
    @objc func didTapBackgroundView() {
        presentable?.didTapOrSwipeToDismiss()
    }
}

// MARK: - Presented View Layout Configuration

extension BottomSheetPresentationController {
    
    fileprivate func installConstraints() {
        guard let containerView = containerView else { return }
        
        // Add a dimmed view behind the view controller
        containerView.addAndPinSubview(backgroundView)
        
        // Add presented view to the containerView
        presentedView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(presentedView)
        
        // We'll use this constraint to handle the keyboard
        let bottomAnchor = presentedView.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor)
        self.bottomAnchor = bottomAnchor
        
        // Add a view between the bottom of the VC and the bottom of the screen for 2 reasons
        // 1. The keyboard animation is sometimes erroneous and results in the bottom of the presented view decoupling from the top of the keyboard, exposing the view behind it.
        // 2. The presented view (BottomSheetVC) does not inherit safeAreaLayoutGuide.bottom
        let coverUpBottomView = UIView()
        containerView.addSubview(coverUpBottomView)
        coverUpBottomView.backgroundColor = presentedView.backgroundColor
        coverUpBottomView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            presentedView.topAnchor.constraint(greaterThanOrEqualTo: containerView.safeAreaLayoutGuide.topAnchor),
            presentedView.leadingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.leadingAnchor),
            presentedView.trailingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.trailingAnchor),
            bottomAnchor,
            
            coverUpBottomView.topAnchor.constraint(equalTo: presentedView.bottomAnchor),
            coverUpBottomView.leadingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.leadingAnchor),
            coverUpBottomView.trailingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.trailingAnchor),
            coverUpBottomView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        fullHeightConstraint.isActive = forceFullHeight
        
        addRoundedCorners(to: presentedView)
        
        registerForKeyboardNotifications()
    }
    
    // MARK: - Helpers
    
    private func addRoundedCorners(to view: UIView) {
        view.layer.maskedCorners =  [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
    }
    
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(adjustForKeyboard),
            name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(adjustForKeyboard),
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    @objc
    private func adjustForKeyboard(notification: Notification) {
        guard
            let keyboardScreenEndFrame =
                (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?
                .cgRectValue,
            let containerView = containerView,
            let bottomAnchor = bottomAnchor
        else {
            return
        }
        
        let keyboardViewEndFrame = containerView.convert(keyboardScreenEndFrame, from: containerView.window)
        let keyboardInViewHeight = containerView.bounds.intersection(keyboardViewEndFrame).height - containerView.safeAreaInsets.bottom
        if notification.name == UIResponder.keyboardWillHideNotification {
            bottomAnchor.constant = 0
        } else {
            bottomAnchor.constant = -keyboardInViewHeight
        }
        
        containerView.setNeedsLayout()
        UIView.animateAlongsideKeyboard(notification) {
            containerView.layoutIfNeeded()
        }
    }
}
