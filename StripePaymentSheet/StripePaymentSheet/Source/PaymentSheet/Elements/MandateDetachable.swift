//
//  MandateDetachable.swift
//  StripePaymentSheet
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

protocol MandateDetachable {
    func mandateString() -> NSAttributedString?
}
