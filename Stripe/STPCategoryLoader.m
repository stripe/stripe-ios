//
//  STPCategoryLoader.m
//  Stripe
//
//  Created by Jack Flintermann on 10/19/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#ifdef STP_STATIC_LIBRARY_BUILD

#import "STPCategoryLoader.h"
#import "PKPayment+Stripe.h"
#import "NSDictionary+Stripe.h"
#import "UIImage+Stripe.h"
#import "NSString+Stripe.h"
#import "NSMutableURLRequest+Stripe.h"
#import "STPAPIClient+ApplePay.h"

@implementation STPCategoryLoader

+ (void)loadCategories {
    linkPKPaymentCategory();
    linkNSDictionaryCategory();
    linkSTPAPIClientApplePayCategory();
    linkUIImageCategory();
    linkNSStringCategory();
    linkNSMutableURLRequestCategory();
    linkUINavigationBarThemeCategory();
    linkUIBarButtonItemCategory();
    linkSTPPaymentConfigurationPrivateCategory();
    linkPKPaymentAuthorizationViewControllerBlocksCategory();
    linkUIToolbarInputAccessoryCategory();
    linkUITableViewCellBordersCategory();
    linkUIViewControllerAlertsCategory();
    linkUIViewControllerPromisesCategory();
    linkUIViewControllerNavigationItemProxyCategory();
    linkNSStringCardBrandsCategory();
    linkNSArrayBoundSafeCategory();
    linkUIViewControllerParentViewControllerCategory();
    linkUINavigationControllerCompletionCategory();
    linkUIViewFirstResponderCategory();
    linkUIViewControllerKeyboardAvoidingCategory();
    linkNSDecimalNumberCurrencyCategory();
    linkNSBundleAppNameCategory();
}

@end

#endif
