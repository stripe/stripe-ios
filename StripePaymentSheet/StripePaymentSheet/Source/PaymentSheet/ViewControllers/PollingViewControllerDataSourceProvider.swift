//
//  PollingViewControllerDataSourceProvider.swift
//  StripePaymentSheet
//
//  Created by Fionn Barrett on 26/07/2023.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

protocol PollingViewControllerDataSourceProvider: AnyObject {
    var instructionLabelAttributedText: NSAttributedString { get }
    func updateTimerCallback(callback: (TimeInterval) -> Void)
}
