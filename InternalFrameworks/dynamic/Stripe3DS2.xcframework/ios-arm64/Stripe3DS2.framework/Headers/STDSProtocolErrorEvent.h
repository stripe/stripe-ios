//
//  STDSProtocolErrorEvent.h
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 3/20/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STDSErrorMessage;

NS_ASSUME_NONNULL_BEGIN

/**
 `STDSProtocolErrorEvent` contains details about erorrs received from or sent to the ACS.
 */
@interface STDSProtocolErrorEvent : NSObject

/**
 Designated initializer for `STDSProtocolErrorEvent`.
 */
- (instancetype)initWithSDKTransactionIdentifier:(NSString *)identifier errorMessage:(STDSErrorMessage *)errorMessage;

/**
 `STDSProtocolErrorEvent` should not be directly initialized.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 Details about the error.
 */
@property (nonatomic, readonly) STDSErrorMessage *errorMessage;

/**
 The SDK Transaction Identifier.
 */
@property (nonatomic, readonly) NSString *sdkTransactionIdentifier;

@end

NS_ASSUME_NONNULL_END
