//
//  CTAButton.swift
//  CardImageVerification Example
//
//  Created by Jaime Park on 11/28/21.
//

import Foundation
import UIKit

///TODO(jaimepark): Make CTAButton with activity indicator an encapsulated object instead of extending uibutton.
extension UIButton {
    func updateButtonState(isLoading: Bool) {
        self.isEnabled = !isLoading
        self.alpha = isLoading ? 0.5 : 1.0
    }
}
