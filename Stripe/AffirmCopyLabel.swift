//
//  AffirmCopyLabel.swift
//
//
//  Created by Reshma Karthikeyan on 2/22/22.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//
import UIKit
@_spi(STP) import StripeUICore

/// For internal SDK use only
@objc(STP_Internal_AffirmCopyLabel)
class AffirmCopyLabel: UIView {

    let logo = NSTextAttachment()
    
    convenience init() {
        self.init(frame: .zero)
        let affirmLabel = UILabel()
        
        let message = NSMutableAttributedString(string: STPLocalizedString("Buy now or pay later with %@.", "Affirm buy now or pay later copy"))
        logo.image = STPImageLibrary.affirmLogo()
        message.replaceOccurrences(of: "%@", with: logo)
        affirmLabel.attributedText = message
        affirmLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        affirmLabel.textColor = CompatibleColor.secondaryLabel
        affirmLabel.numberOfLines = 0
        affirmLabel.sizeToFit()
        addSubview(affirmLabel)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        logo.image = STPImageLibrary.affirmLogo()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
