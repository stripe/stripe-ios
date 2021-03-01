//
//  STDSTransaction.h
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 3/21/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^STDSTransactionVoidBlock)(void);

@class STDSAuthenticationRequestParameters, STDSChallengeParameters;
@protocol STDSChallengeStatusReceiver;

NS_ASSUME_NONNULL_BEGIN

/**
 `STDSTransaction` holds parameters that the 3DS Server requires to create AReq messages and to perform the Challenge Flow.
 */
@interface STDSTransaction : NSObject

/**
 The UI type of the presented challenge for this transaction if applicable. Will be one of
    "none"
    "text"
    "single_select"
    "multi_select"
    "oob"
    "html"
 */
@property (nonatomic, readonly, copy) NSString *presentedChallengeUIType;

/**
 Encrypts device information collected during initialization and returns it along with SDK details.
 
 @return Encrypted device information and details about this SDK.  @see STDSAuthenticationRequestParameters
 
 @exception SDKRuntimeException Thrown if an internal error is encountered.
 */
- (STDSAuthenticationRequestParameters *)createAuthenticationRequestParameters;

/**
 Returns a UIViewController instance displaying the Directory Server logo and a spinner.  Present this during the Authentication Request/Response.
 */
- (UIViewController *)createProgressViewControllerWithDidCancel:(STDSTransactionVoidBlock)didCancel;

/**
 Initiates the challenge process, displaying challenge UI as needed.
 
 @param presentingViewController        The UIViewController used to present the challenge response UIViewController
 @param challengeParameters             Details required to conduct the challenge process.  @see STDSChallengeParameters
 @param challengeStatusReceiver         A callback object to receive the status of the challenge.  See @STDSChallengeStatusReceiver
 @param timeout                         An interval in seconds within which the challenge process will finish.  Must be at least 5 minutes.
 
 @exception STDSInvalidInputException    Thrown if an argument is invalid (e.g. timeout less than 5 minutes).  @see STDSInvalidInputException
 @exception STDSSDKRuntimeException      Thrown if an internal error is encountered, and if you call this method after calling `close`.  @see SDKRuntimeException
 
 @note challengeStatusReceiver must conform to <STDSChallengeStatusReceiver>. This is a workaround: When the static Stripe3DS2 is compiled into Stripe.framework, the resulting swiftinterface and generated .h files reference this protocol. To allow users to build without including Stripe3DS2 directly, we'll take an `id` here instead.
 */
- (void)doChallengeWithViewController:(UIViewController *)presentingViewController
                  challengeParameters:(STDSChallengeParameters *)challengeParameters
              challengeStatusReceiver:(id)challengeStatusReceiver
                              timeout:(NSTimeInterval)timeout;

/**
 Returns the version of the Stripe3DS2 SDK, e.g. @"1.0"
 */
- (NSString *)sdkVersion;

/**
Cleans up resources held by `STDSTransaction`.  Call this when the transaction is completed, if `doChallengeWithChallengeParameters:challengeStatusReceiver:timeout` is not called.
 
 @note Don't use this object after calling this method.  Calling `doChallengeWithViewController:challengeParameters:challengeStatusReceiver:timeout` after calling this method will throw an `STDSSDKRuntimeException`
 */
- (void)close;

/**
 Alternate challenge initiation method meant only for internal use by Stripe SDK.
 */
- (void)doChallengeWithChallengeParameters:(STDSChallengeParameters *)challengeParameters
                   challengeStatusReceiver:(id)challengeStatusReceiver
                                   timeout:(NSTimeInterval)timeout
                         presentationBlock:(void (^)(UIViewController *, void(^)(void)))presentationBlock;

/**
 Function to manually cancel the challenge flow.
 */
- (void)cancelChallengeFlow;

@end

NS_ASSUME_NONNULL_END
