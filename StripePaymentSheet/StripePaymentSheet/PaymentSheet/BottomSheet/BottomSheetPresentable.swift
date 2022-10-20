//
//  BottomSheetPresentable.swift
//  StripePaymentSheet
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

protocol BottomSheetPresentable: UIViewController {
    /// Called when the user taps on the background view or swipes to dismiss.
    /// You should dismiss the view controller
    func didTapOrSwipeToDismiss()
}
