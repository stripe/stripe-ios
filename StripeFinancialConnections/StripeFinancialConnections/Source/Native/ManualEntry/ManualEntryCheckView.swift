//
//  ManualEntryCheckView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/24/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class ManualEntryCheckView: UIView {

    static let height: CGFloat = 96.0

    enum HighlightState: Int {
        case none = 0
        case routingNumber = 1
        case accountNumber = 2
    }

    var highlightState: HighlightState = .none {
        didSet {
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Image.bank_check.makeImage()
        return imageView
    }()

    init() {
        super.init(frame: .zero)
        addSubview(imageView)
        clipsToBounds = true  // we shift `imageView` in the `bounds` of this view, so clip it to bounds
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.sizeToFit()
        imageView.frame = CGRect(
            x: (bounds.width - imageView.bounds.width) / 2,
            y: -1 * CGFloat(highlightState.rawValue) * Self.height,
            width: imageView.bounds.width,
            height: imageView.bounds.height
        )
    }
}
