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

/**
 The API Client to use to make requests.
 
 Defaults to [STPAPIClient sharedClient]
 */
@property (nonatomic, strong) STPAPIClient *apiClient;

/**
 Create a STPPinManagementService, you must provide an implementation of STPIssuingCardEphemeralKeyProvider
 */
- (instancetype)initWithKeyProvider:(id<STPIssuingCardEphemeralKeyProvider>)keyProvider;

/**
 Retrieves a PIN number for a given card,
 this call is asynchronous, implement the completion block to receive the updates
 */
- (void)retrievePin:(NSString *) cardId
     verificationId:(NSString *) verificationId
        oneTimeCode:(NSString *) oneTimeCode
         completion:(STPPinCompletionBlock) completion;

/**
 Updates a PIN number for a given card,
 this call is asynchronous, implement the completion block to receive the updates
 */
- (void)updatePin:(NSString *) cardId
           newPin:(NSString *) newPin
   verificationId:(NSString *) verificationId
      oneTimeCode:(NSString *) oneTimeCode
       completion:(STPPinCompletionBlock) completion;

@end
