//
//  STDSChallengeRequestParameters.h
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 4/1/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STDSJSONEncodable.h"

@class STDSChallengeParameters;

typedef NS_ENUM(NSInteger, STDSChallengeCancelType) {
    /// The cardholder selected "Cancel" from the UI
    STDSChallengeCancelTypeCardholderSelectedCancel,
    
    /// The transaction timed out
    STDSChallengeCancelTypeTransactionTimedOut,
};

NS_ASSUME_NONNULL_BEGIN

@interface STDSChallengeRequestParameters : NSObject <STDSJSONEncodable>

/**
 Convenience initializer to create parameters for the first Challenge Request for a transaction.
 */
- (instancetype)initWithChallengeParameters:(STDSChallengeParameters *)challengeParams
                      transactionIdentifier:(NSString *)transactionIdentifier
                             messageVersion:(NSString *)messageVersion;

/**
 Designated initializer for `STDSChallengeRequestParameters`
 */
- (instancetype)initWithThreeDSServerTransactionIdentifier:(NSString *)threeDSServerTransactionIdentifier
                                  acsTransactionIdentifier:(NSString *)acsTransactionIdentifier
                                            messageVersion:(NSString *)messageVersion
                                  sdkTransactionIdentifier:(NSString *)sdkTransactionIdentifier
                                           requestorAppUrl:(NSString *)requestorAppUrl
                                            sdkCounterStoA:(NSInteger)sdkCounterStoA NS_DESIGNATED_INITIALIZER;

/**
 Returns a new instance of STDSChallengeRequestParameters using the receiver, copying over the properties that are invariant across all CReqs for a given transaction and incrementing sdkCounterStoA.
 */
- (instancetype)nextChallengeRequestParametersByIncrementCounter;

- (instancetype)init NS_UNAVAILABLE;

#pragma mark - Required Properties

/**
 Universally unique transaction identifier assigned by the 3DS SDK to identify a single transaction.
 */
@property (nonatomic, readonly) NSString *sdkTransactionIdentifier;

/**
 Transaction identifier assigned by the 3DS Server to uniquely identify
 a transaction.
 */
@property (nonatomic, readonly) NSString *threeDSServerTransactionIdentifier;

/**
 Transaction identifier assigned by the Access Control Server (ACS)
 to uniquely identify a transaction.
 */
@property (nonatomic, readonly) NSString *acsTransactionIdentifier;

/**
 Identifies the type of message - always "CReq"
 */
@property (nonatomic, readonly) NSString *messageType;

/**
 The protocol version that is supported by the SDK and used for the transaction.
 */
@property (nonatomic, readonly) NSString *messageVersion;

/**
 Counter used as a security measure in the 3DS SDK to ACS secure channel.
 */
@property (nonatomic, readonly) NSString *sdkCounterStoA;

#pragma mark - Optional/Conditional Properties

/**
 The URL for the application that is requesting 3DS2 verification.
 This property can be optionally set and will be included with the
 messages sent to the Directory Server during the challenge flow.
 */
@property (nonatomic, copy, nullable) NSString *threeDSRequestorAppURL;

/**
 A STDSChallengeCancelType wrapped in NSNumber, indicating that the authentication has been canceled.
 */
@property (nonatomic, copy, nullable) NSNumber *challengeCancel;

/**
 Contains the data that the Cardholder entered into the Native UI text field.
 
 @note The setter converts empty strings to nil.
 */
@property (nonatomic, copy, nullable) NSString *challengeDataEntry;

/**
 Data that the Cardholder entered into the HTML UI.
 */
@property (nonatomic, copy, nullable) NSString *challengeHTMLDataEntry;

/**
 Data necessary to support requirements not otherwise defined in the 3- D Secure message.
 */
@property (nonatomic, copy, nullable) NSArray *messageExtension;

/**
 A BOOL indiciating that Cardholder has completed the authentication as requested by selecting the Continue button in an Out- of-Band (OOB) authentication method.
 */
@property (nonatomic, nullable) NSNumber *oobContinue;

/**
 Indicator to resend the challenge information code to the Cardholder.
 */
@property (nonatomic, copy, nullable) NSString *resendChallenge;

/**
 Indicator confirming whether whitelisting was opted by the cardholder.
 */
@property (nonatomic, copy, nullable) NSString *whitelistingDataEntry;

/**
 Indicator informing that the Cardholder submits an empty response (no data entered in the UI).
 */
@property (nonatomic, copy, nullable) NSString *challengeNoEntry;

@end

NS_ASSUME_NONNULL_END
