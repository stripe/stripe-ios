//
//  STPPaymentManager.h
//  Stripe
//
//  Created by Jack Flintermann on 11/11/14.
//
//

#import <Foundation/Foundation.h>
#import "STPCheckoutOptions.h"
#import "STPCheckoutViewController.h"
#import "STPToken.h"

typedef void (^STPPaymentTokenHandler)(STPToken *token, STPTokenSubmissionHandler handler);
typedef void (^STPPaymentCompletionHandler)(BOOL success, NSError *error);

@interface STPPaymentManager : NSObject

- (void)requestPaymentWithOptions:(STPCheckoutOptions *)options
     fromPresentingViewController:(UIViewController *)presentingViewController
                 withTokenHandler:(STPPaymentTokenHandler)tokenHandler
                       completion:(STPPaymentCompletionHandler)completion;

@end
