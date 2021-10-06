//
//  TestModeView.swift
//  StripeiOS
//
//  Created by Nick Porter on 8/24/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

private extension UIColor {
    static var testModeTextColor = UIColor(red: 0.65, green: 0.41, blue: 0.07, alpha: 1.00)
    static var testModeBackgroundColor = UIColor(red: 1.00, green: 0.87, blue: 0.58, alpha: 1.00)
}

/// A badge that indicates if the PaymentSheet is in test mode
class TestModeView: UIView {
    
    private lazy var testLabel: UILabel = {
        let label = UILabel()
        label.text = "TEST MODE"
        label.textColor = UIColor.testModeTextColor
        label.textAlignment = .center
        let fontMetrics = UIFontMetrics(forTextStyle: .body)
        let font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.font = fontMetrics.scaledFont(for: font, maximumPointSize: 12)
        
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.testModeBackgroundColor
        layer.cornerRadius = ElementsUI.defaultCornerRadius
        clipsToBounds = false

        addAndPinSubview(testLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
