//
//  STPPaymentCardEntryViewController.h
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPBlocks.h"
#import "STPCardParams.h"
#import "STPAPIClient.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^STPPaymentCardEntryBlock)(STPToken * __nullable token, STPErrorBlock tokenCompletion);

@interface STPPaymentCardEntryViewController : UIViewController

- (instancetype)initWithAPIClient:(STPAPIClient *)apiClient
                       completion:(STPPaymentCardEntryBlock)completion;

@end

NS_ASSUME_NONNULL_END
