//
//  UIView+PaymentSheetDebugging.swift
//  StripePaymentSheet
//

import UIKit

extension UIView {
    func ambiguousView() -> UIView? {
        for subview in self.subviews {
            if let ambiguousSubview = subview.ambiguousView() {
                return ambiguousSubview
            }
        }
        if hasAmbiguousLayout {
            print("Horizontal axis constraints: \(self.constraintsAffectingLayout(for: .horizontal)))")
            print("Vertical axis constraints: \(self.constraintsAffectingLayout(for: .vertical)))")
            print("For more info, try setting a breakpoint here and calling: \nexpr -l objc -O -- [\(Unmanaged.passUnretained(self).toOpaque()) _autolayoutTrace]")
            print("Will start exercising layout ambiguity every second, watch for moving UI elements!")
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
                if let self {
                    self.exerciseAmbiguityInLayout()
                } else {
                    print("Layout ambiguity has been resolved.")
                    t.invalidate()
                }
            }
           return self
        }
        return nil
    }
}
