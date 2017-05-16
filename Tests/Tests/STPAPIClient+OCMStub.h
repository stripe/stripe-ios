//
//  STPAPIClient+OCMStub.h
//  Stripe
//
//  Created by Brian Dorfman on 5/15/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPAPIClient.h"

@interface STPAPIClient (OCMStub)

+ (void)stub:(id)mockAPIClient
createSourceWithParamsCompletion:(void (^)(STPSourceParams *sourceParams,
                                           STPSourceCompletionBlock completion))stubBlock;

+ (void)stub:(id)mockAPIClient
precheckSourceWithParamsCompletion:(void (^)(STPSourcePrecheckParams *precheckParams,
                                             STPSourcePrecheckCompletionBlock completion))stubBlock;

@end
