//
//  STDSCompletionEvent.h
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 3/20/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 `STDSCompletionEvent` contains information about completion of the challenge process.
 */
@interface STDSCompletionEvent : NSObject

/**
 Designated initializer for `STDSCompletionEvent`.
 */
- (instancetype)initWithSDKTransactionIdentifier:(NSString *)identifier transactionStatus:(NSString *)transactionStatus NS_DESIGNATED_INITIALIZER;

/**
 `STDSCompletionEvent` should not be directly initialized.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 The SDK Transaction ID.
 */
@property (nonatomic, readonly) NSString *sdkTransactionIdentifier;

/**
 The transaction status that was received in the final challenge response.
 */
@property (nonatomic, readonly) NSString *transactionStatus;

@end

NS_ASSUME_NONNULL_END
