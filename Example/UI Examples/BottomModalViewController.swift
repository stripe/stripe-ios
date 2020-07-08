//
//  BottomModalViewController.swift
//  UI Examples
//
//  Created by Yuki Tokuhiro on 7/6/20.
//  Copyright © 2020 Stripe. All rights reserved.
//

import UIKit

class BottomModalViewController: UINavigationController {
    var bottomConstraint: NSLayoutConstraint!

    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
    }
    
    override func viewDidLoad() {
        registerForKeyboardNotifications()
    }
    
    func registerForKeyboardNotifications(){
        //Adding notifies on keyboard appearing
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWasShown(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let info = notification.userInfo else {
            return
        }
        
        let keyboardHeight = keyboardSize.height
        // TODO get the right curve, wow this is annoying
//        let curve = UIView.AnimationOptions(curve) info[UIResponder.keyboardAnimationCurveUserInfoKey] as! UIView.AnimationCurve
        let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: {
            self.bottomConstraint.constant = -keyboardHeight
            self.view.superview?.layoutIfNeeded()
        }, completion: nil)
    }

    @objc func keyboardWillBeHidden(notification: NSNotification){
        var info = notification.userInfo!
        // TODO get the right curve, wow this is annoying
        //        let curve = UIView.AnimationOptions(curve) info[UIResponder.keyboardAnimationCurveUserInfoKey] as! UIView.AnimationCurve
        let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: {
            self.bottomConstraint.constant = 0
            self.view.superview?.layoutIfNeeded()
        }, completion: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
}

extension BottomModalViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
}

extension BottomModalViewController: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let duration = transitionDuration(using: transitionContext)
        let view = transitionContext.view(forKey: .to)!
        let containerView = transitionContext.containerView
        containerView.addSubview(view)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        let height = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        let topConstraint = view.topAnchor.constraint(equalTo: containerView.bottomAnchor)
        bottomConstraint = view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)

        NSLayoutConstraint.activate([
            topConstraint,
            view.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            view.rightAnchor.constraint(equalTo: containerView.rightAnchor),
              
            // TODO get right height, this one is too tall
            view.heightAnchor.constraint(lessThanOrEqualToConstant: 400)
//            view.heightAnchor.constraint(lessThanOrEqualToConstant: height)
        ])
        containerView.setNeedsLayout()
        containerView.layoutIfNeeded()

        // Bounce it up
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: {
            topConstraint.isActive = false
            self.bottomConstraint.isActive = true
            containerView.setNeedsLayout()
            containerView.layoutIfNeeded()
        }, completion: { _ in
            transitionContext.completeTransition(true)
        })
    }
}
