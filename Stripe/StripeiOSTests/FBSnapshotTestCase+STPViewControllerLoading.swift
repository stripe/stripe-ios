//
//  FBSnapshotTestCase+STPViewControllerLoading.swift
//  StripeiOS Tests
//
//  Created by Brian Dorfman on 12/11/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import iOSSnapshotTestCase

extension FBSnapshotTestCase {
    /// Embeds the given controller in a navigation controller, prepares it for
    /// snapshot testing and returns the view controller's view.
    @objc(stp_preparedAndSizedViewForSnapshotTestFromViewController:)
    func stp_preparedAndSizedViewForSnapshotTest(from viewController: UIViewController?) -> UIView?
    {
        let navController = stp_navigationControllerForSnapshotTest(withRootVC: viewController)
        return stp_preparedAndSizedViewForSnapshotTest(from: navController)
    }

    /// Returns a navigation controller initialized with the given root view controller
    /// and prepares it for snapshot testing (adding it to a UIWindow and loading views)
    @objc func stp_navigationControllerForSnapshotTest(
        withRootVC viewController: UIViewController?
    )
        -> UINavigationController?
    {
        var navController: UINavigationController?
        if let viewController = viewController {
            navController = UINavigationController(rootViewController: viewController)
        }
        let testWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        testWindow.rootViewController = navController
        testWindow.isHidden = false

        // Test that views loaded properly + loads them on first call
        XCTAssertNotNil(navController?.view)
        XCTAssertNotNil(viewController?.view)

        return navController
    }

}
