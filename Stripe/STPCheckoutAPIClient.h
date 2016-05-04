//
//  STPCheckoutAPIClient.h
//  Stripe
//
//  Created by Jack Flintermann on 5/3/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPCheckoutAPIVerification.h"
#import "STPCheckoutAccount.h"
#import "STPCheckoutAccountLookup.h"
#import "STPBlocks.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^STPCheckoutVerificationBlock)(STPCheckoutAPIVerification * __nullable verification, NSError * __nullable error);
typedef void (^STPCheckoutLookupBlock)(STPCheckoutAccountLookup * __nullable lookup, NSError * __nullable error);
typedef void (^STPCheckoutAccountBlock)(STPCheckoutAccount * __nullable account, NSError * __nullable error);

@interface STPCheckoutAPIClient : NSObject

- (instancetype)initWithPublishableKey:(NSString *)publishableKey;

- (void)lookupEmail:(NSString *)email
         completion:(STPCheckoutLookupBlock)completion;

- (void)sendSMSToAccountWithEmail:(NSString *)email
                       completion:(STPCheckoutVerificationBlock)completion;

- (void)submitSMSCode:(NSString *)code
      forVerification:(STPCheckoutAPIVerification *)verification
           completion:(STPCheckoutAccountBlock)completion;
//
//- (void)createTokenCompletion:(STPTokenCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
