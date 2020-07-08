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
    
    // TODO - handle dismissal too
//    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        return self
//    }
}

extension BottomModalViewController: UIViewControllerAnimatedTransitioning {
    struct Constants {
        static let dragIndicatorSize = CGSize(width: 40, height: 10)
    }
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let duration = transitionDuration(using: transitionContext)
        let view = transitionContext.view(forKey: .to)!
        let containerView = transitionContext.containerView
        containerView.addSubview(view)

        // Round the top corners
        let radius = 10
        let path = UIBezierPath(roundedRect: view.bounds,
                                byRoundingCorners: [.topLeft, .topRight],
                                cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        view.layer.mask = mask
        
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

        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: {
            // Animate up
            topConstraint.isActive = false
            self.bottomConstraint.isActive = true
            containerView.setNeedsLayout()
            containerView.layoutIfNeeded()
            
            // Fade the underlying VC
            containerView.backgroundColor = UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0.1)

        }, completion: { _ in
            transitionContext.completeTransition(true)
        })
    }
}
