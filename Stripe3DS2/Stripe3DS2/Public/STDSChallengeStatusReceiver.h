//
//  STDSChallengeStatusReceiver.h
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 3/20/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class STDSTransaction, STDSCompletionEvent, STDSRuntimeErrorEvent, STDSProtocolErrorEvent;

NS_ASSUME_NONNULL_BEGIN

/**
 Implement the `STDSChallengeStatusReceiver` protocol to receive challenge status notifications at the end of the challenge process.
 @see `STDSTransaction.doChallenge`
 */
@protocol STDSChallengeStatusReceiver <NSObject>

/**
 Called when the challenge process is completed.
 
 @param completionEvent Information about the completion of the challenge process.  @see `STDSCompletionEvent`
 */
- (void)transaction:(STDSTransaction *)transaction didCompleteChallengeWithCompletionEvent:(STDSCompletionEvent *)completionEvent;

/**
 Called when the user selects the option to cancel the transaction on the challenge screen.
 */
- (void)transactionDidCancel:(STDSTransaction *)transaction;

/**
 Called when the challenge process reaches or exceeds the timeout interval that was passed to `STDSTransaction.doChallenge`
 */
- (void)transactionDidTimeOut:(STDSTransaction *)transaction;

/**
 Called when the 3DS SDK receives an EMV 3-D Secure protocol-defined error message from the ACS.
 
 @param protocolErrorEvent The error code and details.  @see `STDSProtocolErrorEvent`
 */
- (void)transaction:(STDSTransaction *)transaction didErrorWithProtocolErrorEvent:(STDSProtocolErrorEvent *)protocolErrorEvent;

/**
 Called when the 3DS SDK encounters errors during the challenge process. These errors include all errors except those covered by `didErrorWithProtocolErrorEvent`.
 
 @param runtimeErrorEvent The error code and details.  @see `STDSRuntimeErrorEvent`
 */
- (void)transaction:(STDSTransaction *)transaction didErrorWithRuntimeErrorEvent:(STDSRuntimeErrorEvent *)runtimeErrorEvent;

@optional

/**
 Optional method that will be called when the transaction displays a new challenge screen.
 */
- (void)transactionDidPresentChallengeScreen:(STDSTransaction *)transaction;

/**
 Optional method for custom dismissal of the challenge view controller. Meant only for internal use by Stripe SDK.
 */
- (void)dismissChallengeViewController:(UIViewController *)challengeViewController forTransaction:(STDSTransaction *)transaction;

@end

NS_ASSUME_NONNULL_END
