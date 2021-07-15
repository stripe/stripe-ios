//
//  AfterpayPriceBreakdownViewSnapshotTests.swift
//  StripeiOS
//
//  Created by Jaime Park on 6/15/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import FBSnapshotTestCase

@testable import Stripe

class AfterpayPriceBreakdownViewSnapshotTests: FBSnapshotTestCase {
    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func embedInRenderableView(_ priceBreakdownView: AfterpayPriceBreakdownView, width: Int, height: Int) -> UIView {
        let containingView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        containingView.addSubview(priceBreakdownView)
        priceBreakdownView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            priceBreakdownView.leadingAnchor.constraint(equalTo: containingView.leadingAnchor),
            containingView.trailingAnchor.constraint(equalTo: priceBreakdownView.trailingAnchor),
            priceBreakdownView.topAnchor.constraint(equalTo: containingView.topAnchor),
            containingView.bottomAnchor.constraint(equalTo: priceBreakdownView.bottomAnchor),
        ])

        return containingView
    }
    
    func testClearpayInMultiRow() {
        NSLocale.stp_withLocale(as: NSLocale(localeIdentifier: "en_GB") as Locale) { [self] in
            let priceBreakdownView = AfterpayPriceBreakdownView(amount: 1000, currency: "GBP")
            let containingView = embedInRenderableView(priceBreakdownView, width: 320, height: 50)
            
            FBSnapshotVerifyView(containingView)
        }
    }
    
    func testAfterpayInSingleRow() {
        let priceBreakdownView = AfterpayPriceBreakdownView(amount: 1000, currency: "USD")
        let containingView = embedInRenderableView(priceBreakdownView, width: 500, height: 30)
        
        FBSnapshotVerifyView(containingView)
    }
}
