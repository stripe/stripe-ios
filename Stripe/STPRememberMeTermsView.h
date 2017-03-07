//
//  STPRememberMeTermsView.h
//  Stripe
//
//  Created by Jack Flintermann on 5/18/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPTheme.h"
#import "STPInfoFooterView.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^STPRememberMeTermsPushVCBlock)(UIViewController *vc);

@interface STPRememberMeTermsView :  STPInfoFooterView

@property (nonatomic, copy)STPRememberMeTermsPushVCBlock pushViewControllerBlock;

@end

NS_ASSUME_NONNULL_END
