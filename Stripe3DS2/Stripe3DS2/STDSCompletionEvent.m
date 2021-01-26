//
//  STDSCompletionEvent.m
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 3/20/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSCompletionEvent.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STDSCompletionEvent

- (instancetype)initWithSDKTransactionIdentifier:(NSString *)identifier transactionStatus:(NSString *)transactionStatus {
    self = [super init];
    if (self) {
        _sdkTransactionIdentifier = [identifier copy];
        _transactionStatus = [transactionStatus copy];
    }
    return self;
}

@end

NS_ASSUME_NONNULL_END
