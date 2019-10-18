//
//  STPCategoryLoader.m
//  Stripe
//
//  Created by Jack Flintermann on 10/19/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#ifdef STP_STATIC_LIBRARY_BUILD

#import "STPCategoryLoader.h"

#import "NSArray+Stripe.h"
#import "NSBundle+Stripe_AppName.h"
#import "NSCharacterSet+Stripe.h"
#import "NSDecimalNumber+Stripe_Currency.h"
#import "NSDictionary+Stripe.h"
#import "NSError+Stripe.h"
#import "NSMutableURLRequest+Stripe.h"
#import "NSString+Stripe.h"
#import "NSURLComponents+Stripe.h"
#import "PKPayment+Stripe.h"
#import "PKPaymentAuthorizationViewController+Stripe_Blocks.h"
#import "PKAddPaymentPassRequest+Stripe_Error.h"
#import "STPAPIClient+ApplePay.h"
#import "STPAPIClient+PushProvisioning.h"
#import "STPAspects.h"
#import "STPCardValidator+Private.h"
#import "StripeError.h"
#import "UIBarButtonItem+Stripe.h"
#import "UIImage+Stripe.h"
#import "UINavigationBar+Stripe_Theme.h"
#import "UINavigationController+Stripe_Completion.h"
#import "UITableViewCell+Stripe_Borders.h"
#import "UIToolbar+Stripe_InputAccessory.h"
#import "UIView+Stripe_FirstResponder.h"
#import "UIView+Stripe_SafeAreaBounds.h"
#import "UIViewController+Stripe_KeyboardAvoiding.h"
#import "UIViewController+Stripe_NavigationItemProxy.h"
#import "UIViewController+Stripe_ParentViewController.h"
#import "UIViewController+Stripe_Promises.h"

@implementation STPCategoryLoader

+ (void)loadCategories {
    linkAspectsCategory();
    linkNSArrayCategory();
    linkNSBundleAppNameCategory();
    linkNSDecimalNumberCurrencyCategory();
    linkNSDictionaryCategory();
    linkNSErrorCategory();
    linkNSErrorPrivateCategory();
    linkNSMutableURLRequestCategory();
    linkNSStringCategory();
    linkNSURLComponentsCategory();
    linkPKPaymentAuthorizationViewControllerBlocksCategory();
    linkPKPaymentCategory();
    linkPKAddPaymentPassRequestCategory();
    linkSTPAPIClientApplePayCategory();
    linkSTPAPIClientPushProvisioningCategory();
    linkSTPCardValidatorPrivateCategory();
    linkUIBarButtonItemCategory();
    linkUIImageCategory();
    linkUINavigationBarThemeCategory();
    linkUINavigationControllerCompletionCategory();
    linkUITableViewCellBordersCategory();
    linkUIToolbarInputAccessoryCategory();
    linkUIViewControllerKeyboardAvoidingCategory();
    linkUIViewControllerNavigationItemProxyCategory();
    linkUIViewControllerParentViewControllerCategory();
    linkUIViewControllerPromisesCategory();
    linkUIViewFirstResponderCategory();
    linkUIViewSafeAreaBoundsCategory();
    linkNSCharacterSetCategory();
}

@end

#endif
