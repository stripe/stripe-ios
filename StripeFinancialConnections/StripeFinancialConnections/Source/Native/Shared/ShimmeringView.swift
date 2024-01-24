//
//  ShimmeringView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/24/24.
//

import Foundation
import UIKit

class ShimmeringView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        startShimmering()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func startShimmering() {
        self.alpha = 0.30

        UIView.animate(
            withDuration: 1.0,
            delay: 1.0,
            options: [.autoreverse, .repeat, .allowUserInteraction],
            animations: {
                self.alpha = 1.0
            },
            completion: nil
        )
    }

    func stopShimmering() {
        layer.removeAllAnimations()
        self.alpha = 1.0
    }
}
