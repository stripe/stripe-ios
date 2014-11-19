//
//  STPPaymentManager.h
//  Stripe
//
//  Created by Jack Flintermann on 11/11/14.
//
//

#import <Foundation/Foundation.h>
#import "STPCheckoutOptions.h"
#import "STPToken.h"

typedef NS_ENUM(NSInteger, STPPaymentAuthorizationStatus) {
    STPPaymentAuthorizationStatusSuccess, // Merchant auth'd (or expects to auth) the transaction successfully.
    STPPaymentAuthorizationStatusFailure, // Merchant failed to auth the transaction.
};

typedef void (^STPPaymentCompletionHandler)(STPPaymentAuthorizationStatus status);
typedef void (^STPPaymentTokenHandler)(STPToken *token, NSError *error, STPPaymentCompletionHandler handler);

@interface STPPaymentManager : NSObject

- (void)requestPaymentWithOptions:(STPCheckoutOptions *)options
     fromPresentingViewController:(UIViewController *)presentingViewController
                 withTokenHandler:(STPPaymentTokenHandler)tokenHandler;

@end
