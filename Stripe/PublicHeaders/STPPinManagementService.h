//
//  STPAPIClient+PinManagement.h
//  Stripe
//
//  Created by Arnaud Cavailhez on 4/29/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPAPIClient.h"
#import "STPEphemeralKeyProvider.h"

/**
 STPAPIClient extensions to manage PIN on Stripe Issuing cards
 */
@interface STPPinManagementService : NSObject

- (instancetype)initWithKeyProvider:(id<STPIssuingCardEphemeralKeyProvider>)keyProvider;

- (void)retrievePin:(NSString *) cardId
     verificationId:(NSString *) verificationId
        oneTimeCode:(NSString *) oneTimeCode
         completion:(STPPinCompletionBlock) completion;

- (void)updatePin:(NSString *) cardId
           newPin:(NSString *) newPin
   verificationId:(NSString *) verificationId
      oneTimeCode:(NSString *) oneTimeCode
       completion:(STPPinCompletionBlock) completion;

@end
