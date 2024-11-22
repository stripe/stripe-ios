//
//  STDSThreeDS2Service.h
//  Stripe3DS2
//
//  Created by Cameron Sabol on 1/22/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STDSConfigParameters;
@class STDSTransaction;
@class STDSUICustomization;
@class STDSWarning;
@protocol STDSAnalyticsDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 `STDSThreeDS2Service` is the main 3DS SDK interface and provides methods to process transactions.
 */
@interface STDSThreeDS2Service : NSObject

/**
 A list of warnings that may be populated once the SDK has been initialized.
 */
@property (nonatomic, readonly, nullable) NSArray<STDSWarning *> *warnings;

/**
 Initializes the 3DS SDK instance.

 This method should be called at the start of the payment stage of a transaction.
 **Note: Until the `STDSThreeDS2Service instance is initialized, it will be unusable.**

 - Performs security checks
 - Collects device information

 @param config Configuration information that will be used during initialization. @see STDSConfigParameters
 @param locale Optional override for the locale to use in UI. If `nil`, will default to the current system locale.
 @param uiSettings Optional custom UI settings.  If `nil`, will default to `[STDSUICustomization defaultSettings]`.
 This argument is copied; any further changes to the customization object have no effect.  @see STDSUICustomization

 @exception STDSInvalidInputException Will throw an `STDSInvalidInputException` if `config` is `nil` or any of `config`, `locale`, or `uiSettings` are invalid. @see STDSInvalidInputException
 @exception STDSAlreadyInitializedException Will throw an `STDSAlreadyInitializedException` if the 3DS SDK instance has already been initialized. @see STDSSDKAlreadyInitializedException
 @exception STDSRuntimeException Will throw an `STDSRuntimeException` if there is an internal error in the SDK. @see STDSRuntimeException
 */
- (void)initializeWithConfig:(STDSConfigParameters *)config
                      locale:(nullable NSLocale *)locale
                  uiSettings:(nullable STDSUICustomization *)uiSettings;

- (void)initializeWithConfig:(STDSConfigParameters *)config
                      locale:(nullable NSLocale *)locale
                  uiSettings:(nullable STDSUICustomization *)uiSettings
           analyticsDelegate:(nonnull id<STDSAnalyticsDelegate>)analyticsDelegate;

/**
 Creates and returns an instance of `STDSTransaction`.

 @param directoryServerID The Directory Server identifier returned in the authentication response
 @param protocolVersion 3DS protocol version according to which the transaction will be created. Uses the default value of 2.2.0 if nil

 @exception STDSNotInitializedException Will throw an `STDSNotInitializedException` if the the `STDSThreeDS2Service` instance hasn't been initialized with a call to `initializeWithConfig:locale:uiSettings:`. @see STDSNotInitializedException
 @exception STDSInvalidInputException Will throw an `STDSInvalidInputException` if `directoryServerID` is not recognized or if the `protocolVersion` is not supported by this version of the SDK. @see STDSInvalidInputException
 @exception STDSRuntimeException Will throw an `STDSRuntimeException` if there is an internal error in the SDK. @see STDSRuntimeException
 */
- (STDSTransaction *)createTransactionForDirectoryServer:(NSString *)directoryServerID
                                     withProtocolVersion:(nullable NSString *)protocolVersion;

/**
 Creates and returns an instance of `STDSTransaction` using a custom directory server certificate.
 Will return nil if unable to create a certificate from the provided params.

 @param directoryServerID The Directory Server identifier returned in the authentication response
 @param serverKeyID An additional authentication key used by some Directory Servers
 @param certificateString A Base64-encoded PEM or DER formatted certificate string containing the directory server's public key
 @param rootCertificateStrings An arry of base64-encoded PEM or DER formatted certificate strings containing the DS root certificate used for signature checks
 @param protocolVersion 3DS protocol version according to which the transaction will be created. Uses the default value of 2.2.0 if nil

 @exception STDSNotInitializedException Will throw an `STDSNotInitializedException` if the the `STDSThreeDS2Service` instance hasn't been initialized with a call to `initializeWithConfig:locale:uiSettings:`. @see STDSNotInitializedException
 @exception STDSInvalidInputException Will throw an `STDSInvalidInputException` if the `protocolVersion` is not supported by this version of the SDK. @see STDSInvalidInputException
 */
- (nullable STDSTransaction *)createTransactionForDirectoryServer:(NSString *)directoryServerID
                                                      serverKeyID:(nullable NSString *)serverKeyID
                                                certificateString:(NSString *)certificateString
                                           rootCertificateStrings:(NSArray<NSString *> *)rootCertificateStrings
                                              withProtocolVersion:(nullable NSString *)protocolVersion;

@end

NS_ASSUME_NONNULL_END
