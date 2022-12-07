//
//  STDSBrandingView.h
//  Stripe3DS2
//
//  Created by Andrew Harrison on 2/27/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface STDSBrandingView: UIView

/// The issuer image to present in the branding view.
@property (nonatomic, strong) UIImage *issuerImage;

/// The payment system image to present in the branding view.
@property (nonatomic, strong) UIImage *paymentSystemImage;

@end

NS_ASSUME_NONNULL_END
