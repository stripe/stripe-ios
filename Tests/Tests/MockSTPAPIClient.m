//
//  MockSTPAPIClient.m
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 3/29/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

#import "MockSTPAPIClient.h"

@implementation MockSTPAPIClient

- (instancetype)init {
    return [super initWithPublishableKey:@"mock"];
}

+ (nonnull instancetype)mockWithToken:(STPToken *)token {
    MockSTPAPIClient *client = [[self alloc] init];
    client.token = token;
    return client;
}

+ (nonnull instancetype)mockWithError:(NSError *)error {
    MockSTPAPIClient *client = [[self alloc] init];
    client.error = error;
    return client;
}

- (void)createTokenWithData:(__unused NSData *)data completion:(STPTokenCompletionBlock)completion {
    if (self.error) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            completion(nil, self.error);
        });
    }
    else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            completion(self.token ?: [STPToken new], nil);
        });
    }
}

@end
