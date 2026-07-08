//
//  BottomSheetPresentable.swift
//  StripePaymentSheet
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif

protocol BottomSheetPresentable: UIViewController {
    /// The corner radius for the bottom sheet. If nil, a default value will be used.
    var sheetCornerRadius: CGFloat? { get }
    /// Called when the user taps on the background view or swipes to dismiss.
    /// You should dismiss the view controller
    func didTapOrSwipeToDismiss()
}
