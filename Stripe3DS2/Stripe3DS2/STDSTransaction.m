//
//  STDSTransaction.m
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 3/21/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSTransaction.h"
#import "STDSTransaction+Private.h"

#import "STDSBundleLocator.h"
#import "NSDictionary+DecodingHelpers.h"
#import "NSError+Stripe3DS2.h"
#import "NSString+JWEHelpers.h"
#import "STDSACSNetworkingManager.h"
#import "STDSAuthenticationRequestParameters.h"
#import "STDSChallengeRequestParameters.h"
#import "STDSCompletionEvent.h"
#import "STDSChallengeParameters.h"
#import "STDSChallengeResponseObject.h"
#import "STDSChallengeResponseViewController.h"
#import "STDSChallengeStatusReceiver.h"
#import "STDSDeviceInformation.h"
#import "STDSEllipticCurvePoint.h"
#import "STDSEphemeralKeyPair.h"
#import "STDSErrorMessage+Internal.h"
#import "STDSException+Internal.h"
#import "STDSInvalidInputException.h"
#import "STDSJSONWebEncryption.h"
#import "STDSJSONWebSignature.h"
#import "STDSProgressViewController.h"
#import "STDSProtocolErrorEvent.h"
#import "STDSRuntimeErrorEvent.h"
#import "STDSRuntimeException.h"
#import "STDSSecTypeUtilities.h"
#import "STDSStripe3DS2Error.h"

static const NSTimeInterval kMinimumTimeout = 5 * 60;
static NSString * const kStripeLOA = @"3DS_LOA_SDK_STIN_020100_00162";
static NSString * const kULTestLOA = @"3DS_LOA_SDK_PPFU_020100_00007";

NS_ASSUME_NONNULL_BEGIN

@interface STDSTransaction() <STDSChallengeResponseViewControllerDelegate>

@property (nonatomic, weak) id<STDSChallengeStatusReceiver> challengeStatusReceiver;
@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, strong, nullable) STDSChallengeResponseViewController *challengeResponseViewController;
/// Stores the most recent parameters used to make a CReq
@property (nonatomic, nullable) STDSChallengeRequestParameters *challengeRequestParameters;
/// YES if `close` was called or the challenge flow finished.
@property (nonatomic, getter=isCompleted) BOOL completed;
@end

@implementation STDSTransaction
{
    STDSDeviceInformation *_deviceInformation;
    STDSDirectoryServer _directoryServer;
    STDSEphemeralKeyPair *_ephemeralKeyPair;
    STDSThreeDSProtocolVersion _protocolVersion;
    NSString *_identifier;

    STDSDirectoryServerCertificate *_customDirectoryServerCertificate;
    NSArray<NSString *> *_rootCertificateStrings;
    NSString *_customDirectoryServerID;
    NSString *_serverKeyID;
    
    STDSACSNetworkingManager *_networkingManager;
    
    STDSUICustomization *_uiCustomization;
}

- (instancetype)initWithDeviceInformation:(STDSDeviceInformation *)deviceInformation
                          directoryServer:(STDSDirectoryServer)directoryServer
                          protocolVersion:(STDSThreeDSProtocolVersion)protocolVersion
                          uiCustomization:(nonnull STDSUICustomization *)uiCustomization {
    self = [super init];
    if (self) {
        _deviceInformation = deviceInformation;
        _directoryServer = directoryServer;
        _protocolVersion = protocolVersion;
        _completed = NO;
        _identifier = [NSUUID UUID].UUIDString.lowercaseString;
        _ephemeralKeyPair = [STDSEphemeralKeyPair ephemeralKeyPair];
        _uiCustomization = uiCustomization;
        if (_ephemeralKeyPair == nil) {
            return nil;
        }
    }
    
    return self;
}

- (instancetype)initWithDeviceInformation:(STDSDeviceInformation *)deviceInformation
                        directoryServerID:(NSString *)directoryServerID
                              serverKeyID:(nullable NSString *)serverKeyID
               directoryServerCertificate:(STDSDirectoryServerCertificate *)directoryServerCertificate
                   rootCertificateStrings:(NSArray<NSString *> *)rootCertificateStrings
                          protocolVersion:(STDSThreeDSProtocolVersion)protocolVersion
                          uiCustomization:(STDSUICustomization *)uiCustomization {
    self = [super init];
    if (self) {
        _deviceInformation = deviceInformation;
        _directoryServer = STDSDirectoryServerCustom;
        _customDirectoryServerCertificate = directoryServerCertificate;
        _rootCertificateStrings = rootCertificateStrings;
        _customDirectoryServerID = [directoryServerID copy];
        _serverKeyID = [serverKeyID copy];
        _protocolVersion = protocolVersion;
        _completed = NO;
        _identifier = [NSUUID UUID].UUIDString.lowercaseString;
        _ephemeralKeyPair = [STDSEphemeralKeyPair ephemeralKeyPair];
        _uiCustomization = uiCustomization;
        if (_ephemeralKeyPair == nil) {
            return nil;
        }
    }

    return self;
}

- (NSString *)sdkVersion {
    return [[STDSBundleLocator stdsResourcesBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

- (NSString *)presentedChallengeUIType {
    switch (self.challengeResponseViewController.response.acsUIType) {

        case STDSACSUITypeNone:
            return @"none";

        case STDSACSUITypeText:
            return @"text";

        case STDSACSUITypeSingleSelect:
            return @"single_select";

        case STDSACSUITypeMultiSelect:
            return @"multi_select";

        case STDSACSUITypeOOB:
            return @"oob";

        case STDSACSUITypeHTML:
            return @"html";
    }
}

- (STDSAuthenticationRequestParameters *)createAuthenticationRequestParameters {
    NSError *error = nil;
    NSString *encryptedDeviceData = nil;

    if (_directoryServer == STDSDirectoryServerCustom) {
        encryptedDeviceData = [STDSJSONWebEncryption encryptJSON:_deviceInformation.dictionaryValue
                                                 withCertificate:_customDirectoryServerCertificate
                                               directoryServerID:_customDirectoryServerID
                                                     serverKeyID:_serverKeyID
                                                           error:&error];
    } else {
        encryptedDeviceData = [STDSJSONWebEncryption encryptJSON:_deviceInformation.dictionaryValue
                                              forDirectoryServer:_directoryServer
                                                           error:&error];
    }
    if (encryptedDeviceData == nil) {
        @throw [STDSRuntimeException exceptionWithMessage:@"Error encrypting device information %@", error];
    }
    
    return [[STDSAuthenticationRequestParameters alloc] initWithSDKTransactionIdentifier:_identifier
                                                                              deviceData:encryptedDeviceData
                                                                   sdkEphemeralPublicKey:_ephemeralKeyPair.publicKeyJWK
                                                                        sdkAppIdentifier:[self _sdkAppIdentifier]
                                                                      sdkReferenceNumber:self.useULTestLOA ? kULTestLOA : kStripeLOA
                                                                          messageVersion:[self _messageVersion]];
}

- (UIViewController *)createProgressViewControllerWithDidCancel:(void (^)(void))didCancel {
    return [[STDSProgressViewController alloc] initWithDirectoryServer:[self _directoryServerForUI] uiCustomization:_uiCustomization didCancel:didCancel];
}

- (void)doChallengeWithViewController:(UIViewController *)presentingViewController
                  challengeParameters:(STDSChallengeParameters *)challengeParameters
              challengeStatusReceiver:(id)challengeStatusReceiver
                              timeout:(NSTimeInterval)timeout {
    if (self.isCompleted) {
        @throw [STDSRuntimeException exceptionWithMessage:@"The transaction has already completed."];
    } else if (timeout < kMinimumTimeout) {
        @throw [STDSInvalidInputException exceptionWithMessage:@"Timeout value of %lf seconds is less than 5 minutes", timeout];
    }
    self.presentingViewController = presentingViewController;
    self.challengeStatusReceiver = challengeStatusReceiver;
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:(timeout) target:self selector:@selector(_didTimeout) userInfo:nil repeats:NO];

    self.challengeRequestParameters = [[STDSChallengeRequestParameters alloc] initWithChallengeParameters:challengeParameters
                                                                                    transactionIdentifier:_identifier
                                                                                           messageVersion:[self _messageVersion]];

    STDSJSONWebSignature *jws = [[STDSJSONWebSignature alloc] initWithString:challengeParameters.acsSignedContent allowNilKey:self.bypassTestModeVerification];
    BOOL validJWS = jws != nil;
    if (validJWS && !self.bypassTestModeVerification) {
        if (_customDirectoryServerCertificate != nil) {
            if (_rootCertificateStrings.count == 0) {
                validJWS = NO;
            } else {
                validJWS = [STDSJSONWebEncryption verifyJSONWebSignature:jws withCertificate:_customDirectoryServerCertificate rootCertificates:_rootCertificateStrings];
            }
        } else {
            validJWS = [STDSJSONWebEncryption verifyJSONWebSignature:jws forDirectoryServer:_directoryServer];
        }
    }
    if (!validJWS) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [challengeStatusReceiver transaction:self
                   didErrorWithRuntimeErrorEvent:[[STDSRuntimeErrorEvent alloc] initWithErrorCode:kSTDSRuntimeErrorCodeEncryptionError errorMessage:@"Error verifying JWS response."]];
            [self _cleanUp];
        });
        return;
    }
    
    NSError *jsonError = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jws.payload options:0 error:&jsonError];
    NSDictionary *acsEphmeralKeyJWK = [json _stds_dictionaryForKey:@"acsEphemPubKey" required:NO error:NULL];
    STDSEllipticCurvePoint *acsEphemeralKey = [[STDSEllipticCurvePoint alloc] initWithJWK:acsEphmeralKeyJWK];
    NSString *acsURLString = [json _stds_stringForKey:@"acsURL" required:NO error:NULL];
    NSURL *acsURL = [NSURL URLWithString:acsURLString ?: @""];
    if (acsEphemeralKey  == nil || acsURL == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [challengeStatusReceiver transaction:self
                   didErrorWithRuntimeErrorEvent:[[STDSRuntimeErrorEvent alloc] initWithErrorCode:kSTDSRuntimeErrorCodeParsingError errorMessage:[NSString stringWithFormat:@"Unable to create key or url from ACS json: %@\n\n jsonError: %@", json, jsonError]]];
            [self _cleanUp];
        });
        return;
    }
    
    NSData *ecdhSecret = [_ephemeralKeyPair createSharedSecretWithEllipticCurveKey:acsEphemeralKey];
    if (ecdhSecret == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [challengeStatusReceiver transaction:self
                   didErrorWithRuntimeErrorEvent:[[STDSRuntimeErrorEvent alloc] initWithErrorCode:kSTDSRuntimeErrorCodeEncryptionError errorMessage:@"Error during Diffie-Helman key exchange"]];
            [self _cleanUp];
        });
        return;
    }
    
    NSData *contentEncryptionKeySDKtoACS = STDSCreateConcatKDFWithSHA256(ecdhSecret, 32, self.useULTestLOA ? kULTestLOA : kStripeLOA);
    // These two keys are intentionally identical
    // ref. Protocol and Core Functions Specification Version 2.2.0 Section 6.2.3.2 & 6.2.3.3
    // "In this version of the specification [contentEncryptionKeyACStoSDK] and [contentEncryptionKeySDKtoACS]
    // are extracted with the same value."
    NSData *contentEncryptionKeyACStoSDK = [contentEncryptionKeySDKtoACS copy];
    
    _networkingManager = [[STDSACSNetworkingManager alloc] initWithURL:acsURL
                                               sdkContentEncryptionKey:contentEncryptionKeySDKtoACS
                                               acsContentEncryptionKey:contentEncryptionKeyACStoSDK
                                              acsTransactionIdentifier:self.challengeRequestParameters.acsTransactionIdentifier];
    // Start the Challenge flow
    STDSImageLoader *imageLoader = [[STDSImageLoader alloc] initWithURLSession:NSURLSession.sharedSession];
    self.challengeResponseViewController = [[STDSChallengeResponseViewController alloc] initWithUICustomization:_uiCustomization imageLoader:imageLoader directoryServer:[self _directoryServerForUI]];
    self.challengeResponseViewController.delegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.challengeResponseViewController];
    
    // Disable "swipe to dismiss" behavior in iOS 13
    if ([navigationController respondsToSelector:NSSelectorFromString(@"isModalInPresentation")]) {
        [navigationController setValue:@YES forKey:@"modalInPresentation"];
    }
    
    [self.presentingViewController presentViewController:navigationController animated:YES completion:^{
        [self _makeChallengeRequest:self.challengeRequestParameters didCancel:NO];
    }];
    
}

- (void)close {
    [self _cleanUp];
}

- (void)dealloc {
    [self _cleanUp];
}

#pragma mark - Private

// When we get a directory certificate and ID from the server, we mark it as Custom for encryption,
// but may have a correct mapping to a DS logo for the UI
- (STDSDirectoryServer)_directoryServerForUI {
    return (_customDirectoryServerID != nil) ? STDSDirectoryServerForID(_customDirectoryServerID) : _directoryServer;
}

- (void)_makeChallengeRequest:(STDSChallengeRequestParameters *)challengeRequestParameters didCancel:(BOOL)didCancel {
    [self.challengeResponseViewController setLoading];
    __weak STDSTransaction *weakSelf = self;
    [_networkingManager submitChallengeRequest:self.challengeRequestParameters
                                withCompletion:^(id<STDSChallengeResponse> _Nullable response, NSError * _Nullable error) {
                                    STDSTransaction *strongSelf = weakSelf;
                                    if (strongSelf == nil || strongSelf.isCompleted) {
                                        return;
                                    }
                                    // Parsing or network errors
                                    if (response == nil || error) {
                                        if (!error) {
                                            error = [NSError errorWithDomain:STDSStripe3DS2ErrorDomain code:STDSErrorCodeUnknownError userInfo:nil];
                                        }
                                        [strongSelf _handleError:error];
                                        return;
                                    }
                                    // Consistency errors (e.g. acsTransID changes)
                                    NSError *validationError;
                                    if (![strongSelf _validateChallengeResponse:response error:&validationError]) {
                                        [strongSelf _handleError:validationError];
                                        return;
                                    }
                                    [strongSelf _handleChallengeResponse:response didCancel:didCancel];
                                }];
}

- (BOOL)_validateChallengeResponse:(id<STDSChallengeResponse>)challengeResponse error:(NSError **)outError {
    NSError *error;
    if (![challengeResponse.acsTransactionID isEqualToString:self.challengeRequestParameters.acsTransactionIdentifier] ||
        ![challengeResponse.threeDSServerTransactionID isEqualToString:self.challengeRequestParameters.threeDSServerTransactionIdentifier] ||
        ![challengeResponse.sdkTransactionID isEqualToString:self.challengeRequestParameters.sdkTransactionIdentifier]) {
        error = [NSError errorWithDomain:STDSStripe3DS2ErrorDomain code:STDSErrorMessageErrorTransactionIDNotRecognized userInfo:nil];
    } else if (![challengeResponse.messageVersion isEqualToString:self.challengeRequestParameters.messageVersion]) {
        error = [NSError _stds_invalidJSONFieldError:@"messageVersion"];
    } else if (!self.bypassTestModeVerification && ![challengeResponse.acsCounterACStoSDK isEqualToString:self.challengeRequestParameters.sdkCounterStoA]) {
        error = [NSError errorWithDomain:STDSStripe3DS2ErrorDomain code:STDSErrorCodeDecryptionVerification userInfo:nil];
    }
    
    if (error && outError) {
        *outError = error;
    }
    return error == nil;
}

- (void) _handleError:(NSError *)error {
    // All the codes corresponding to errors that we treat as protocol errors (ie send to the ACS and report as an STDSProtocolErrorEvent)
    NSSet *protocolErrorCodes = [NSSet setWithArray:@[@(STDSErrorCodeUnknownMessageType),
                                                      @(STDSErrorCodeJSONFieldInvalid),
                                                      @(STDSErrorCodeJSONFieldMissing),
                                                      @(STDSErrorCodeReceivedErrorMessage),
                                                      @(STDSErrorMessageErrorTransactionIDNotRecognized),
                                                      @(STDSErrorCodeUnrecognizedCriticalMessageExtension),
                                                      @(STDSErrorCodeDecryptionVerification)]];
    if (error.domain == STDSStripe3DS2ErrorDomain) {
        NSString *sdkTransactionIdentifier = _identifier;
        NSString *acsTransactionIdentifier = self.challengeRequestParameters.acsTransactionIdentifier;
        NSString *messageVersion = [self _messageVersion];
        STDSErrorMessage *errorMessage;
        switch (error.code) {
            case STDSErrorCodeReceivedErrorMessage:
                errorMessage = error.userInfo[STDSStripe3DS2ErrorMessageErrorKey];
                break;
            case STDSErrorCodeUnknownMessageType:
                errorMessage = [STDSErrorMessage errorForInvalidMessageWithACSTransactionID:acsTransactionIdentifier messageVersion:messageVersion];
                break;
            case STDSErrorCodeJSONFieldInvalid:
                errorMessage = [STDSErrorMessage errorForJSONFieldInvalidWithACSTransactionID:acsTransactionIdentifier messageVersion:messageVersion error:error];
                break;
            case STDSErrorCodeJSONFieldMissing:
                errorMessage = [STDSErrorMessage errorForJSONFieldMissingWithACSTransactionID:acsTransactionIdentifier messageVersion:messageVersion error:error];
                break;
            case STDSErrorCodeTimeout:
                errorMessage = [STDSErrorMessage errorForTimeoutWithACSTransactionID:acsTransactionIdentifier messageVersion:messageVersion];
                break;
            case STDSErrorMessageErrorTransactionIDNotRecognized:
                errorMessage = [STDSErrorMessage errorForUnrecognizedIDWithACSTransactionID:acsTransactionIdentifier messageVersion:messageVersion];
                break;
            case STDSErrorCodeUnrecognizedCriticalMessageExtension:
                errorMessage = [STDSErrorMessage errorForUnrecognizedCriticalMessageExtensionsWithACSTransactionID:acsTransactionIdentifier messageVersion:messageVersion error:error];
                break;
            case STDSErrorCodeDecryptionVerification:
                errorMessage = [STDSErrorMessage errorForDecryptionErrorWithACSTransactionID:acsTransactionIdentifier messageVersion:messageVersion];
                break;
            default:
                break;
        }
        
        // Send the ErrorMessage (unless we received one)
        if (error.code != STDSErrorCodeReceivedErrorMessage && errorMessage != nil) {
            [_networkingManager sendErrorMessage:errorMessage];
        }
        
        // If it's a protocol error, call back to the challengeStatusReceiver
        if ([protocolErrorCodes containsObject:@(error.code)] && errorMessage != nil) {
            STDSProtocolErrorEvent *protocolErrorEvent = [[STDSProtocolErrorEvent alloc] initWithSDKTransactionIdentifier:sdkTransactionIdentifier
                                                                                                             errorMessage:errorMessage];
            [self.challengeStatusReceiver transaction:self didErrorWithProtocolErrorEvent:protocolErrorEvent];
        }
        
    }
    
    if (error.domain != STDSStripe3DS2ErrorDomain || ![protocolErrorCodes containsObject:@(error.code)]) {
        // This error is not a protocol error, and therefore a runtime error.
        NSString *errorCode = [NSString stringWithFormat:@"%ld", (long)error.code];
        STDSRuntimeErrorEvent *runtimeErrorEvent = [[STDSRuntimeErrorEvent alloc] initWithErrorCode:errorCode errorMessage:error.localizedDescription];
        [self.challengeStatusReceiver transaction:self didErrorWithRuntimeErrorEvent:runtimeErrorEvent];
    }
    
    [self.challengeResponseViewController dismissViewControllerAnimated:YES completion:nil];
    [self _cleanUp];
}

- (void)_handleChallengeResponse:(id<STDSChallengeResponse>)challengeResponse didCancel:(BOOL)didCancel {
    if (challengeResponse.challengeCompletionIndicator) {
        // Final CRes
        // We need to pass didCancel to here because we can't distinguish between cancellation and auth failure from the CRes
        // (they both result in a transactionStatus of "N")
        if (didCancel) {
            // We already dismissed the view controller
            [self.challengeStatusReceiver transactionDidCancel:self];
            [self _cleanUp];
        } else {
            [self.challengeResponseViewController dismissViewControllerAnimated:YES completion:nil];
            STDSCompletionEvent *completionEvent = [[STDSCompletionEvent alloc] initWithSDKTransactionIdentifier:_identifier
                                                                                               transactionStatus:challengeResponse.transactionStatus];
            [self.challengeStatusReceiver transaction:self didCompleteChallengeWithCompletionEvent:completionEvent];
            [self _cleanUp];
        }
    } else {
        [self.challengeResponseViewController setChallengeResponse:challengeResponse animated:YES];

        if ([self.challengeStatusReceiver respondsToSelector:@selector(transactionDidPresentChallengeScreen:)]) {
            [self.challengeStatusReceiver transactionDidPresentChallengeScreen:self];
        }
    }
}

- (void)_cleanUp {
    [self.timeoutTimer invalidate];
    self.completed = YES;
    self.challengeResponseViewController = nil;
    self.challengeStatusReceiver = nil;
    _networkingManager = nil;
}

- (void)_didTimeout {
    [self.challengeResponseViewController dismissViewControllerAnimated:YES completion:nil];
    [_networkingManager sendErrorMessage:[STDSErrorMessage errorForTimeoutWithACSTransactionID:self.challengeRequestParameters.acsTransactionIdentifier messageVersion:[self _messageVersion]]];
    [self.challengeStatusReceiver transactionDidTimeOut:self];
    [self _cleanUp];
}

#pragma mark Helpers

- (nullable NSString *)_messageVersion {
    NSString *messageVersion = STDSThreeDSProtocolVersionStringValue(_protocolVersion);
    if (messageVersion == nil) {
        @throw [STDSRuntimeException exceptionWithMessage:@"Error determining message version."];
    }
    return messageVersion;
}

/// Convenience method to construct a CSV from the names of each STDSChallengeResponseSelectionInfo in the given array
- (NSString *)_csvForChallengeResponseSelectionInfo:(NSArray<id<STDSChallengeResponseSelectionInfo>> *)selectionInfoArray {
    NSMutableArray *selectionInfoNames = [NSMutableArray new];
    for (id<STDSChallengeResponseSelectionInfo> selectionInfo in selectionInfoArray) {
        [selectionInfoNames addObject:selectionInfo.name];
    }
    return [selectionInfoNames componentsJoinedByString:@","];
}

/// Returns a UUID unique to the app version
- (NSString *)_sdkAppIdentifier {
    static NSString * const appIdentifierKeyPrefix = @"STDSStripe3DS2AppIdentifierKey";
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"";
    NSString *appIdentifierUserDefaultsKey = [appIdentifierKeyPrefix stringByAppendingString:appVersion];
    NSString *appIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:appIdentifierUserDefaultsKey];
    if (appIdentifier == nil) {
        appIdentifier = [[NSUUID UUID] UUIDString].lowercaseString;
        // Clean up any previous app identifiers
        NSSet *previousKeys = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] keysOfEntriesPassingTest:^BOOL (NSString *key, id obj, BOOL *stop) {
            return [key hasPrefix:appIdentifierKeyPrefix] && ![key isEqualToString:appIdentifierUserDefaultsKey];
        }];
        for (NSString *key in previousKeys) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
        }
    }
    [[NSUserDefaults standardUserDefaults] setObject:appIdentifier forKey:appIdentifierUserDefaultsKey];
    return appIdentifier;
}

#pragma mark - STDSChallengeResponseViewController

- (void)challengeResponseViewController:(nonnull STDSChallengeResponseViewController *)viewController didSubmitInput:(nonnull NSString *)userInput {
    self.challengeRequestParameters = [self.challengeRequestParameters nextChallengeRequestParametersByIncrementCounter];
    self.challengeRequestParameters.challengeDataEntry = userInput;
    [self _makeChallengeRequest:self.challengeRequestParameters didCancel:NO];
}

- (void)challengeResponseViewController:(nonnull STDSChallengeResponseViewController *)viewController didSubmitSelection:(nonnull NSArray<id<STDSChallengeResponseSelectionInfo>> *)selection {
    self.challengeRequestParameters = [self.challengeRequestParameters nextChallengeRequestParametersByIncrementCounter];
    self.challengeRequestParameters.challengeDataEntry = [self _csvForChallengeResponseSelectionInfo:selection];
    [self _makeChallengeRequest:self.challengeRequestParameters didCancel:NO];
}

- (void)challengeResponseViewControllerDidOOBContinue:(nonnull STDSChallengeResponseViewController *)viewController {
    self.challengeRequestParameters = [self.challengeRequestParameters nextChallengeRequestParametersByIncrementCounter];
    self.challengeRequestParameters.oobContinue = @(YES);
    [self _makeChallengeRequest:self.challengeRequestParameters didCancel:NO];
}

- (void)challengeResponseViewControllerDidCancel:(STDSChallengeResponseViewController *)viewController {
    self.challengeRequestParameters = [self.challengeRequestParameters nextChallengeRequestParametersByIncrementCounter];
    self.challengeRequestParameters.challengeCancel = @(STDSChallengeCancelTypeCardholderSelectedCancel);
    [viewController dismissViewControllerAnimated:YES completion:nil];
    [self _makeChallengeRequest:self.challengeRequestParameters didCancel:YES];
}

- (void)challengeResponseViewControllerDidRequestResend:(STDSChallengeResponseViewController *)viewController {
    self.challengeRequestParameters = [self.challengeRequestParameters nextChallengeRequestParametersByIncrementCounter];
    self.challengeRequestParameters.resendChallenge = @"Y";
    [self _makeChallengeRequest:self.challengeRequestParameters didCancel:NO];
}

- (void)challengeResponseViewController:(nonnull STDSChallengeResponseViewController *)viewController didSubmitHTMLForm:(nonnull NSString *)form {
    self.challengeRequestParameters = [self.challengeRequestParameters nextChallengeRequestParametersByIncrementCounter];
    self.challengeRequestParameters.challengeHTMLDataEntry = form;
    [self _makeChallengeRequest:self.challengeRequestParameters didCancel:NO];
}

@end

NS_ASSUME_NONNULL_END
