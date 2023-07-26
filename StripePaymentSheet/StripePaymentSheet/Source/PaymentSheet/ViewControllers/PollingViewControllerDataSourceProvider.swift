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

class PaymentMethodDataSourceProvider: PollingViewControllerDataSourceProvider {
    var deadline: Date
    var instructionLabelAttributedText: NSAttributedString {
        let timeRemaining = dateFormatter.string(from: timeRemaining) ?? ""
        let attrText = NSMutableAttributedString(string: String(format: .Localized.open_upi_app, timeRemaining))
        attrText.addAttributes([.foregroundColor: appearance.colors.primary], range: NSString(string: attrText.string).range(of: timeRemaining))
        return attrText
    }
    let appearance: PaymentSheet.Appearance

    // MARK: public

    public func updateTimerCallback(callback: (TimeInterval) -> Void){
        callback(timeRemaining)
    }

    init(appearance: PaymentSheet.Appearance, deadline: Date) {
        self.appearance = appearance
        self.deadline = deadline
    }

    // MARK: private

    var timeRemaining: TimeInterval {
        return Date().compatibleDistance(to: deadline)
    }

    var dateFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        if timeRemaining > 60 {
            formatter.zeroFormattingBehavior = .dropLeading
        } else {
            formatter.zeroFormattingBehavior = .pad
        }
        formatter.allowedUnits = [.minute, .second]
        return formatter
    }
}

class UPIPaymentMethodDataSourceProvider: PaymentMethodDataSourceProvider{

    override var instructionLabelAttributedText: NSAttributedString {
        let timeRemaining = dateFormatter.string(from: timeRemaining) ?? ""
        let attrText = NSMutableAttributedString(string: String(format: .Localized.open_upi_app, timeRemaining))
        attrText.addAttributes([.foregroundColor: appearance.colors.primary], range: NSString(string: attrText.string).range(of: timeRemaining))
        return attrText
    }

    init(appearance: PaymentSheet.Appearance) {
        let deadline = Date().addingTimeInterval(60 * 5)
        super.init(appearance: appearance, deadline: deadline)
    }
}

class BLIKPaymentMethodDataSourceProvider: PaymentMethodDataSourceProvider{

    override var instructionLabelAttributedText: NSAttributedString {
        let timeRemaining = dateFormatter.string(from: timeRemaining) ?? ""
        let attrText = NSMutableAttributedString(string: String(format: .Localized.approve_payment, timeRemaining))
        attrText.addAttributes([.foregroundColor: appearance.colors.primary], range: NSString(string: attrText.string).range(of: timeRemaining))
        return attrText
    }

    init(appearance: PaymentSheet.Appearance) {
        let deadline = Date().addingTimeInterval(60)
        super.init(appearance: appearance, deadline: deadline)
    }
}
