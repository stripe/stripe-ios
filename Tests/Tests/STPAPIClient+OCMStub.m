//
//  STPAPIClient+OCMStub.m
//  Stripe
//
//  Created by Brian Dorfman on 5/15/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPAPIClient+OCMStub.h"

#import <OCMock/OCMock.h>

@implementation STPAPIClient (OCMStub)

+ (void)stub:(id)mockAPIClient createSourceWithParamsCompletion:(void (^)(STPSourceParams *, STPSourceCompletionBlock))stubBlock {
    OCMStub([mockAPIClient createSourceWithParams:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPSourceParams *sourceParams;
        STPSourceCompletionBlock completion;
        [invocation getArgument:&sourceParams atIndex:2];
        [invocation getArgument:&completion atIndex:3];
        stubBlock(sourceParams, completion);
    });
}

+ (void)stub:(id)mockAPIClient precheckSourceWithParamsCompletion:(void (^)(STPSourcePrecheckParams *, STPSourcePrecheckCompletionBlock))stubBlock {
    OCMStub([mockAPIClient precheckSourceWithParams:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPSourcePrecheckParams *precheckParams;
        STPSourcePrecheckCompletionBlock completion;
        [invocation getArgument:&precheckParams atIndex:2];
        [invocation getArgument:&completion atIndex:3];
        stubBlock(precheckParams, completion);
    });
}

@end
