//
//  ContentCenteringScrollView.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/4/22.
//

import UIKit

/// A scroll view that automatically centers itself when its bounds or content size is changed
final class ContentCenteringScrollView: UIScrollView {

    override var bounds: CGRect {
        didSet {
            if oldValue.size != bounds.size {
                updateContentInset()
            }
        }
    }

    override var contentSize: CGSize {
        didSet {
            if oldValue != contentSize {
                updateContentInset()
            }
        }
    }

    private func updateContentInset() {
        var contentOffset = CGPoint.zero
        if contentSize.width > bounds.width {
            contentOffset.x = (contentSize.width - bounds.width) / 2
        }
        if contentSize.height > bounds.height {
            contentOffset.y = (contentSize.height - bounds.height) / 2
        }
        self.contentOffset = contentOffset
    }
}
