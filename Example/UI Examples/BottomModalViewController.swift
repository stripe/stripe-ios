//
//  BottomModalViewController.swift
//  UI Examples
//
//  Created by Yuki Tokuhiro on 7/6/20.
//  Copyright © 2020 Stripe. All rights reserved.
//

import UIKit

class BottomModalViewController: UINavigationController {
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
//        navigationBar.
    }
    
    override func viewDidLoad() {
        registerForKeyboardNotifications()
    }
    
    func registerForKeyboardNotifications(){
        //Adding notifies on keyboard appearing
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func deregisterFromKeyboardNotifications(){
        //Removing notifies on keyboard appearing
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWasShown(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        

        //Need to calculate keyboard exact size due to Apple suggestions
//        self.scrollView.isScrollEnabled = true
//        var info = notification.userInfo!
//        let keyboardSize = (info[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
//        let contentInsets : UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize!.height, right: 0.0)
//
//        self.scrollView.contentInset = contentInsets
//        self.scrollView.scrollIndicatorInsets = contentInsets
//
//        var aRect : CGRect = self.view.frame
//        aRect.size.height -= keyboardSize!.height
//        if let activeField = self.activeField {
//            if (!aRect.contains(activeField.frame.origin)){
//                self.scrollView.scrollRectToVisible(activeField.frame, animated: true)
//            }
//        }
    }

    @objc func keyboardWillBeHidden(notification: NSNotification){
        //Once keyboard disappears, restore original positions
//        var info = notification.userInfo!
//        let keyboardSize = (info[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
//        let contentInsets : UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: -keyboardSize!.height, right: 0.0)
//        self.scrollView.contentInset = contentInsets
//        self.scrollView.scrollIndicatorInsets = contentInsets
//        self.view.endEditing(true)
//        self.scrollView.isScrollEnabled = false
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
            view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
            containerView.setNeedsLayout()
            containerView.layoutIfNeeded()
        }, completion: { _ in
            transitionContext.completeTransition(true)
        })
    }
}
