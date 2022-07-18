//
//  FinancialConnectionsNavigationController.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/6/22.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore


protocol FinancialConnectionsNavigationControllerDelegate: AnyObject {
    func financialConnectionsNavigationDidClose(
        _ navigationController: FinancialConnectionsNavigationController
    )
}

class FinancialConnectionsNavigationController: UINavigationController {
    
    weak var dismissDelegate: FinancialConnectionsNavigationControllerDelegate?
    
    // MARK: - UIViewController
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if isBeingDismissed {
            dismissDelegate?.financialConnectionsNavigationDidClose(self)
        }
    }
}

// MARK: - `UINavigationController` Modifications

// The purpose of this extension is to consolidate in one place
// all the common changes to `UINavigationController`
extension FinancialConnectionsNavigationController {
    
    func configureAppearanceForNative() {
        if #available(iOS 13.0, *) {
            let backButtonImage = Image.back_arrow.makeImage(template: false)
            let appearance = UINavigationBarAppearance()
            appearance.setBackIndicatorImage(backButtonImage, transitionMaskImage: backButtonImage)
            appearance.backgroundColor = UIColor.white
            appearance.shadowColor = .clear // remove border
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.compactAppearance = appearance
            
            // change the back button color
            navigationBar.tintColor = UIColor.textDisabled
        }
        navigationBar.isTranslucent = false
    }
    
    static func configureNavigationItemForNative(_ navigationItem: UINavigationItem?, closeItem: UIBarButtonItem) {
        navigationItem?.titleView = {
            let stripeLogoImageView = UIImageView(image: Image.stripe_logo.makeImage(template: true))
            stripeLogoImageView.tintColor = UIColor.textBrand
            stripeLogoImageView.contentMode = .scaleAspectFit
            stripeLogoImageView.frame = CGRect(x: 0, y: 0, width: 100, height: 16)
            // If `titleView` is directly set to the `UIImageView`
            // we can't control the sizing...so we create a `containerView`
            // so we can control `UIImageView` sizing.
            let containerView = UIView()
            containerView.addSubview(stripeLogoImageView)
            stripeLogoImageView.center = containerView.center
            stripeLogoImageView.autoresizingMask = [.flexibleTopMargin, .flexibleRightMargin, .flexibleBottomMargin, .flexibleLeftMargin]
            return containerView
        }()
        navigationItem?.backButtonTitle = ""
        navigationItem?.rightBarButtonItem = closeItem
    }
}
