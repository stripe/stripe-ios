//
//  PaneLayoutView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/12/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

/// Reusable view that separates panes into two parts:
/// 1. A scroll view for content
/// 2. A footer that is "locked" and does not get affected by scroll view
final class PaneLayoutView: UIView {
    
    private weak var scrollViewContentView: UIView?
    
    init(contentView: UIView, footerView: UIView) {
        self.scrollViewContentView = contentView
        super.init(frame: .zero)
        
        let scrollView = UIScrollView()
        scrollView.addAndPinSubview(contentView)
        
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                scrollView,
                footerView,
            ]
        )
        verticalStackView.spacing = 0
        verticalStackView.axis = .vertical
        addAndPinSubview(verticalStackView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addToView(_ view: UIView) {
        view.addAndPinSubviewToSafeArea(self)
        scrollViewContentView?.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
    }
}
