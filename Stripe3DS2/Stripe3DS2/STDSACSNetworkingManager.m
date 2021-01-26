//
//  STDSACSNetworkingManager..m
//  Stripe3DS2
//
//  Created by Cameron Sabol on 4/3/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSACSNetworkingManager.h"

#import "STDSChallengeRequestParameters.h"
#import "STDSChallengeResponseObject.h"
#import "STDSJSONEncoder.h"
#import "STDSJSONWebEncryption.h"
#import "STDSStripe3DS2Error.h"
#import "STDSErrorMessage+Internal.h"
#import "NSError+Stripe3DS2.h"

NS_ASSUME_NONNULL_BEGIN

/// [Req 239] requires us to abort if the ACS does not respond with the CRes message within 10 seconds.
static const NSTimeInterval kTimeoutInterval = 10;

@implementation STDSACSNetworkingManager {
    NSURL *_acsURL;
    NSData *_sdkContentEncryptionKey;
    NSData *_acsContentEncryptionKey;
    NSString *_acsTransactionIdentifier;

    NSURLSession *_urlSession;
    NSURLSessionTask * _Nullable _currentTask;
}

- (instancetype)initWithURL:(NSURL *)acsURL
    sdkContentEncryptionKey:(NSData *)sdkCEK
    acsContentEncryptionKey:(NSData *)acsCEK
   acsTransactionIdentifier:(nonnull NSString *)acsTransactionID {
    self = [super init];
    if (self) {
        _acsURL = acsURL;
        _sdkContentEncryptionKey = sdkCEK;
        _acsContentEncryptionKey = acsCEK;
        _acsTransactionIdentifier = [acsTransactionID copy];
        _urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]
                                                    delegate:nil
                                               delegateQueue:[NSOperationQueue mainQueue]];
    }

    return self;
}

- (void)dealloc {
    [_urlSession finishTasksAndInvalidate];
}

- (void)submitChallengeRequest:(STDSChallengeRequestParameters *)request withCompletion:(void (^)(id<STDSChallengeResponse> _Nullable, NSError * _Nullable))completion {

    NSAssert(_currentTask == nil, @"%@ is not intended to handle multiple concurrent tasks.", NSStringFromClass([self class]));
    if (_currentTask != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil, [NSError errorWithDomain:STDSStripe3DS2ErrorDomain
                                                code:STDSErrorCodeAssertionFailed
                                            userInfo:@{@"assertion": [NSString stringWithFormat:@"%@ is not intended to handle multiple concurrent tasks.", NSStringFromClass([self class])]}]);
        });
        return;
    }

    NSDictionary *requestJSON = [STDSJSONEncoder dictionaryForObject:request];
    NSError *encryptionError = nil;
    NSString *encryptedRequest = [STDSJSONWebEncryption directEncryptJSON:requestJSON
                                                 withContentEncryptionKey:_sdkContentEncryptionKey
                                                      forACSTransactionID:_acsTransactionIdentifier
                                                                    error:&encryptionError];

    if (encryptedRequest != nil) {
        NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:_acsURL];
        urlRequest.HTTPMethod = @"POST";
        urlRequest.timeoutInterval = kTimeoutInterval;
        [urlRequest setValue:@"application/jose;charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
        __weak __typeof(self) weakSelf = self;
        NSURLSessionUploadTask *requestTask = [_urlSession uploadTaskWithRequest:[urlRequest copy] fromData:[encryptedRequest dataUsingEncoding:NSUTF8StringEncoding] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {

            __typeof(self) strongSelf = weakSelf;
            if (strongSelf == nil) {
                return;
            }

            strongSelf->_currentTask = nil;

            if (data != nil) {
                NSError *decryptionError = nil;
                NSDictionary *decrypted = [STDSJSONWebEncryption decryptData:data
                                                    withContentEncryptionKey:strongSelf->_acsContentEncryptionKey
                                                                       error:&decryptionError];
                if (decrypted != nil) {
                    NSError *decodingError = nil;
                    id<STDSChallengeResponse> response = [strongSelf decodeJSON:decrypted error:&decodingError];
                    completion(response, decodingError);
                } else {
                    completion(nil, decryptionError);
                }
            } else {
                if (error.code == NSURLErrorTimedOut) {
                    // We convert timeout errors for convenience, since the SDK must treat them differently from generic network errors.
                    error = [NSError _stds_timedOutError];
                }
                completion(nil, error);
            }

        }];
        _currentTask = requestTask;
        [requestTask resume];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil, encryptionError);
        });
    }
}

- (void)sendErrorMessage:(STDSErrorMessage *)errorMessage {
    NSDictionary *requestJSON = [STDSJSONEncoder dictionaryForObject:errorMessage];
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:_acsURL];
    urlRequest.HTTPMethod = @"POST";
    [urlRequest setValue:@"application/JSON; charset = UTF-8" forHTTPHeaderField:@"Content-Type"];
    NSURLSessionUploadTask *requestTask = [_urlSession uploadTaskWithRequest:[urlRequest copy]
                                                                    fromData:[NSJSONSerialization dataWithJSONObject:requestJSON options:0 error:nil]
                                                           completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                                               // no-op
                                                           }];
    [requestTask resume];
}

#pragma mark - Helpers

/**
 Returns an STDSChallengeResponseObject instance decoded from the given dict, or populates the error argument.
 */
- (nullable id<STDSChallengeResponse>)decodeJSON:(NSDictionary *)dict error:(NSError * _Nullable *)outError {
    NSString *kErrorMessageType = @"Erro";
    NSString *kChallengeResponseType = @"CRes";
    NSString *messageType = dict[@"messageType"];
    
    NSError *error;
    id<STDSChallengeResponse> decodedObject;
    
    if ([messageType isEqualToString:kErrorMessageType]) {
        // Error message type
        STDSErrorMessage *errorMessage = [STDSErrorMessage decodedObjectFromJSON:dict error:nil];
        NSDictionary *userInfo = errorMessage ? @{STDSStripe3DS2ErrorMessageErrorKey: errorMessage} : @{};
        error = [NSError errorWithDomain:STDSStripe3DS2ErrorDomain
                                    code:STDSErrorCodeReceivedErrorMessage
                                userInfo:userInfo];
    } else if ([messageType isEqualToString:kChallengeResponseType]) {
        // CRes message type
        decodedObject = [STDSChallengeResponseObject decodedObjectFromJSON:dict error:&error];
    } else {
        // Unknown message type
        error = [NSError errorWithDomain:STDSStripe3DS2ErrorDomain
                                    code:STDSErrorCodeUnknownMessageType
                                userInfo:nil];
    }
    
    if (error && outError) {
        *outError = error;
    }
    return decodedObject;
}

@end

NS_ASSUME_NONNULL_END
