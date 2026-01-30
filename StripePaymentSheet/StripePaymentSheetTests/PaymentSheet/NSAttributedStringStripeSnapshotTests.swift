//
//  NSAttributedString+StripeSnapshotTests.swift
//  StripePaymentSheet
//
//  Created by George Birch on 10/21/25.
//

import StripeCoreTestUtils
import SwiftUI
import UIKit

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripeUICore

@MainActor
class NSAttributedStringStripeSnapshotTests: STPSnapshotTestCase {

    func testPmmePromoString_UILabel_ImageAsset() {
        let template = "Buy now or pay later with <img/>"
        let image = Image.affirm_copy.makeImage()
        let attributedString = NSMutableAttributedString.pmmePromoString(
            font: .boldSystemFont(ofSize: 20),
            textColor: UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0),
            template: template,
            substitution: ("<img/>", image),
            infoMessage: "Learn more"
        )

        let label = UILabel()
        label.attributedText = attributedString
        label.numberOfLines = 0

        verify(label)
    }

    func testPmmePromoString_UILabel_SystemImage() {
        let template = "4 interest-free payments of $12.50 with {partner}"
        let systemImage = UIImage(systemName: "creditcard.fill")!
        let attributedString = NSMutableAttributedString.pmmePromoString(
            font: .systemFont(ofSize: 14),
            textColor: .darkGray,
            template: template,
            substitution: ("{partner}", systemImage),
            infoMessage: "Learn more"
        )

        let label = UILabel()
        label.attributedText = attributedString
        label.numberOfLines = 0

        verify(label)
    }

    func testPmmePromoString_UILabel_NoSubstitution() {
        let template = "Flexible payment options available"
        let attributedString = NSMutableAttributedString.pmmePromoString(
            font: .italicSystemFont(ofSize: 14),
            textColor: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0),
            template: template,
            substitution: nil,
            infoMessage: "Learn more"
        )

        let label = UILabel()
        label.attributedText = attributedString
        label.numberOfLines = 0

        verify(label)
    }

    // MARK: - Helper Methods

    private func verify(
        _ label: UILabel,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let size = label.systemLayoutSizeFitting(
            CGSize(width: 300, height: UIView.layoutFittingExpandedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        label.bounds = CGRect(origin: .zero, size: size)
        STPSnapshotVerifyView(label, identifier: identifier, file: file, line: line)
    }
}
