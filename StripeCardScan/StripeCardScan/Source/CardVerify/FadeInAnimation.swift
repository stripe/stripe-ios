//
//  FadeInAnimation.swift
//  CardScan
//
//  Created by Jaime Park on 8/16/19.
//

import UIKit

extension UIView {

    func fadeIn(_ duration: TimeInterval? = 0.4, onCompletion: (() -> Void)? = nil) {
        self.alpha = 0
        self.isHidden = false
        UIView.animate(
            withDuration: duration!,
            animations: { self.alpha = 1 },
            completion: { (_: Bool) in
                if let complete = onCompletion { complete() }
            }
        )
    }

    func fadeBorderColorIn(
        _ duration: TimeInterval? = 0.4,
        withColor: UIColor,
        onCompletion: (() -> Void)? = nil
    ) {
        self.isHidden = false
        UIView.animate(
            withDuration: duration!,
            animations: { self.layer.borderColor = withColor.cgColor },
            completion: { (_: Bool) in
                if let complete = onCompletion { complete() }
            }
        )
    }

    func fadeOut(_ duration: TimeInterval? = 0.4, onCompletion: (() -> Void)? = nil) {
        self.alpha = 1
        self.isHidden = true
        UIView.animate(
            withDuration: duration!,
            animations: { self.alpha = 0 },
            completion: { (_: Bool) in
                if let complete = onCompletion { complete() }
            }
        )
    }
}

extension UILabel {
    func fadeTextColorIn(
        _ duration: TimeInterval? = 0.4,
        withColor: UIColor,
        onCompletion: (() -> Void)? = nil
    ) {
        self.isHidden = false
        UIView.animate(
            withDuration: duration!,
            animations: { self.textColor = withColor },
            completion: { (_: Bool) in
                if let complete = onCompletion { complete() }
            }
        )
    }
}
