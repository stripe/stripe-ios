//
//  STPCoreScrollViewController.swift
//  Stripe
//
//  Created by Brian Dorfman on 1/6/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/// This is the base class for all Stripe scroll view controllers. It is intended
/// for use only by Stripe classes, you should not subclass it yourself in your app.
public class STPCoreScrollViewController: STPCoreViewController {
    /// This returns the scroll view being managed by the view controller
    @objc public lazy var scrollView: UIScrollView = {
        createScrollView()
    }()

    /// This method is used by the base implementation to create the object
    /// backing the `scrollView` property. Subclasses can override to change the
    /// type of the scroll view (eg UITableView or UICollectionView instead of
    /// UIScrollView).

    func createScrollView() -> UIScrollView {
        return UIScrollView()
    }

    override func createAndSetupViews() {
        super.createAndSetupViews()
        view.addSubview(scrollView)
    }

    /// :nodoc:
    @objc
    public override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.contentInsetAdjustmentBehavior = .automatic
    }

    /// :nodoc:
    @objc
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
    }

    @objc override func updateAppearance() {
        super.updateAppearance()

        scrollView.backgroundColor = theme.primaryBackgroundColor
        scrollView.tintColor = theme.accentColor

        if STPColorUtils.colorIsBright(theme.primaryBackgroundColor) {
            scrollView.indicatorStyle = .black
        } else {
            scrollView.indicatorStyle = .white
        }
    }
}
