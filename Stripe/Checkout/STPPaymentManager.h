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

@interface STPPaymentManager : NSObject

- (void)requestPaymentWithOptions:(STPCheckoutOptions *)options
     fromPresentingViewController:(UIViewController *)presentingViewController
                       completion:(void (^)(STPToken *token, NSError *error, STPPaymentCompletionHandler handler))completion;

@end
