//
//  STDSChallengeResponseObject.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 2/25/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSChallengeResponseObject.h"

#import "NSDictionary+DecodingHelpers.h"
#import "NSError+Stripe3DS2.h"
#import "STDSChallengeResponseSelectionInfoObject.h"
#import "STDSChallengeResponseImageObject.h"
#import "STDSChallengeResponseMessageExtensionObject.h"
#import "NSString+JWEHelpers.h"
#import "STDSStripe3DS2Error.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STDSChallengeResponseObject

@synthesize threeDSServerTransactionID = _threeDSServerTransactionID;
@synthesize acsCounterACStoSDK = _acsCounterACStoSDK;
@synthesize acsTransactionID = _acsTransactionID;
@synthesize acsHTML = _acsHTML;
@synthesize acsHTMLRefresh = _acsHTMLRefresh;
@synthesize acsUIType = _acsUIType;
@synthesize challengeCompletionIndicator = _challengeCompletionIndicator;
@synthesize challengeInfoHeader = _challengeInfoHeader;
@synthesize challengeInfoLabel = _challengeInfoLabel;
@synthesize challengeInfoText = _challengeInfoText;
@synthesize challengeAdditionalInfoText = _challengeAdditionalInfoText;
@synthesize showChallengeInfoTextIndicator = _showChallengeInfoTextIndicator;
@synthesize challengeSelectInfo = _challengeSelectInfo;
@synthesize expandInfoLabel = _expandInfoLabel;
@synthesize expandInfoText = _expandInfoText;
@synthesize issuerImage = _issuerImage;
@synthesize messageExtensions = _messageExtensions;
@synthesize messageType = _messageType;
@synthesize messageVersion = _messageVersion;
@synthesize oobAppURL = _oobAppURL;
@synthesize oobAppLabel = _oobAppLabel;
@synthesize oobContinueLabel = _oobContinueLabel;
@synthesize paymentSystemImage = _paymentSystemImage;
@synthesize resendInformationLabel = _resendInformationLabel;
@synthesize sdkTransactionID = _sdkTransactionID;
@synthesize submitAuthenticationLabel = _submitAuthenticationLabel;
@synthesize whitelistingInfoText = _whitelistingInfoText;
@synthesize whyInfoLabel = _whyInfoLabel;
@synthesize whyInfoText = _whyInfoText;
@synthesize transactionStatus = _transactionStatus;

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ -- completion: %@, count: %@", [super description], @(self.challengeCompletionIndicator), self.acsCounterACStoSDK];
}

- (instancetype)initWithThreeDSServerTransactionID:(NSString *)threeDSServerTransactionID
                                acsCounterACStoSDK:(NSString *)acsCounterACStoSDK
                                  acsTransactionID:(NSString *)acsTransactionID
                                           acsHTML:(NSString * _Nullable)acsHTML
                                    acsHTMLRefresh:(NSString * _Nullable)acsHTMLRefresh
                                         acsUIType:(STDSACSUIType)acsUIType
                      challengeCompletionIndicator:(BOOL)challengeCompletionIndicator
                               challengeInfoHeader:(NSString * _Nullable)challengeInfoHeader
                                challengeInfoLabel:(NSString * _Nullable)challengeInfoLabel
                                 challengeInfoText:(NSString * _Nullable)challengeInfoText
                       challengeAdditionalInfoText:(NSString * _Nullable)challengeAdditionalInfoText
                    showChallengeInfoTextIndicator:(BOOL)showChallengeInfoTextIndicator
                               challengeSelectInfo:(NSArray<id<STDSChallengeResponseSelectionInfo>> * _Nullable)challengeSelectInfo
                                   expandInfoLabel:(NSString * _Nullable)expandInfoLabel
                                    expandInfoText:(NSString * _Nullable)expandInfoText
                                       issuerImage:(id<STDSChallengeResponseImage> _Nullable)issuerImage
                                 messageExtensions:(NSArray<id<STDSChallengeResponseMessageExtension>> * _Nullable)messageExtensions
                                    messageVersion:(NSString *)messageVersion
                                         oobAppURL:(NSURL * _Nullable)oobAppURL
                                       oobAppLabel:(NSString * _Nullable)oobAppLabel
                                  oobContinueLabel:(NSString * _Nullable)oobContinueLabel
                                paymentSystemImage:(id<STDSChallengeResponseImage> _Nullable)paymentSystemImage
                            resendInformationLabel:(NSString * _Nullable)resendInformationLabel
                                  sdkTransactionID:(NSString *)sdkTransactionID
                         submitAuthenticationLabel:(NSString * _Nullable)submitAuthenticationLabel
                              whitelistingInfoText:(NSString * _Nullable)whitelistingInfoText
                                      whyInfoLabel:(NSString * _Nullable)whyInfoLabel
                                       whyInfoText:(NSString * _Nullable)whyInfoText
                                 transactionStatus:(NSString * _Nullable)transactionStatus {
    self = [super init];
    
    if (self) {
        _threeDSServerTransactionID = [threeDSServerTransactionID copy];
        _acsCounterACStoSDK = [acsCounterACStoSDK copy];
        _acsTransactionID = [acsTransactionID copy];
        _acsHTML = [acsHTML copy];
        _acsHTMLRefresh = [acsHTMLRefresh copy];
        _acsUIType = acsUIType;
        _challengeCompletionIndicator = challengeCompletionIndicator;
        _challengeInfoHeader = [challengeInfoHeader copy];
        _challengeInfoLabel = [challengeInfoLabel copy];
        _challengeInfoText = [challengeInfoText copy];
        _challengeAdditionalInfoText = [challengeAdditionalInfoText copy];
        _showChallengeInfoTextIndicator = showChallengeInfoTextIndicator;
        _challengeSelectInfo = [challengeSelectInfo copy];
        _expandInfoLabel = [expandInfoLabel copy];
        _expandInfoText = [expandInfoText copy];
        _issuerImage = issuerImage;
        _messageExtensions = [messageExtensions copy];
        _messageType = @"CRes";
        _messageVersion = [messageVersion copy];
        _oobAppURL = oobAppURL;
        _oobAppLabel = [oobAppLabel copy];
        _oobContinueLabel = [oobContinueLabel copy];
        _paymentSystemImage = paymentSystemImage;
        _resendInformationLabel = [resendInformationLabel copy];
        _sdkTransactionID = [sdkTransactionID copy];
        _submitAuthenticationLabel = [submitAuthenticationLabel copy];
        _whitelistingInfoText = [whitelistingInfoText copy];
        _whyInfoLabel = [whyInfoLabel copy];
        _whyInfoText = [whyInfoText copy];
        _transactionStatus = [transactionStatus copy];
    }
    
    return self;
}

#pragma mark Private Helpers

+ (NSDictionary<NSString *, NSNumber *> *)acsUITypeStringMapping {
    return @{
             @"01": @(STDSACSUITypeText),
             @"02": @(STDSACSUITypeSingleSelect),
             @"03": @(STDSACSUITypeMultiSelect),
             @"04": @(STDSACSUITypeOOB),
             @"05": @(STDSACSUITypeHTML),
             };
}

/// The message extension identifiers that we support.
+ (NSSet *)supportedMessageExtensions {
    return [NSSet new];
}

#pragma mark STDSJSONDecodable

+ (nullable instancetype)decodedObjectFromJSON:(nullable NSDictionary *)json error:(NSError **)outError {
    if (json == nil) {
        return nil;
    }
    NSError *error;
    
#pragma mark Required
    NSString *threeDSServerTransactionID = [json _stds_stringForKey:@"threeDSServerTransID" validator:^BOOL (NSString *value) {
        return [[NSUUID alloc] initWithUUIDString:value] != nil;
    } required:YES error:&error];
    NSString *acsCounterACStoSDK = [json _stds_stringForKey:@"acsCounterAtoS" required:YES error:&error];
    NSString *acsTransactionID = [json _stds_stringForKey:@"acsTransID" required:YES error:&error];
    NSString *challengeCompletionIndicatorRawString = [json _stds_stringForKey:@"challengeCompletionInd" validator:^BOOL (NSString *value) {
        return [value isEqualToString:@"N"] || [value isEqualToString:@"Y"];
    } required:YES error:&error];
    // There is only one valid messageType value for this object (@"CRes"), so we don't store it.
    [json _stds_stringForKey:@"messageType" validator:^BOOL (NSString *value) {
        return [value isEqualToString:@"CRes"];
    } required:YES error:&error];
    NSString *messageVersion = [json _stds_stringForKey:@"messageVersion" required:YES error:&error];
    NSString *sdkTransactionID = [json _stds_stringForKey:@"sdkTransID" required:YES error:&error];
    
    BOOL challengeCompletionIndicator = challengeCompletionIndicatorRawString.boolValue;
    
    STDSACSUIType acsUIType = STDSACSUITypeNone;
    if (!challengeCompletionIndicator) {
        NSString *acsUITypeRawString = [json _stds_stringForKey:@"acsUiType" validator:^BOOL (NSString *value) {
            return [self acsUITypeStringMapping][value] != nil;
        } required:YES error:&error];
        
        acsUIType = [self acsUITypeStringMapping][acsUITypeRawString].integerValue;
    }
    
    if (error) {
        // We failed to populate a required field
        if (outError) {
            *outError = error;
        }
        return nil;
    }
    
    // At this point all the above values are valid: e.g. raw string representations of a BOOL or enum will map to a valid value.
    
#pragma mark Conditional
    NSString *encodedAcsHTML = [json _stds_stringForKey:@"acsHTML" required:(acsUIType == STDSACSUITypeHTML) error: &error];
    NSString *acsHTML = [encodedAcsHTML _stds_base64URLDecodedString];
    if (encodedAcsHTML && !acsHTML) {
        // html was not valid base64url
        error = [NSError _stds_invalidJSONFieldError:@"acsHTML"];
    }
    
    NSArray<id<STDSChallengeResponseSelectionInfo>> *challengeSelectInfo = [json _stds_arrayForKey:@"challengeSelectInfo"
                                                                                  arrayElementType:[STDSChallengeResponseSelectionInfoObject class]
                                                                                          required:(acsUIType == STDSACSUITypeSingleSelect || acsUIType == STDSACSUITypeMultiSelect)
                                                                                             error:&error];
    NSString *oobContinueLabel = [json _stds_stringForKey:@"oobContinueLabel" required:(acsUIType == STDSACSUITypeOOB) error:&error];
    NSString *submitAuthenticationLabel = [json _stds_stringForKey:@"submitAuthenticationLabel" required:(acsUIType == STDSACSUITypeText || acsUIType == STDSACSUITypeSingleSelect || acsUIType == STDSACSUITypeMultiSelect || acsUIType == STDSACSUITypeText) error:&error];
    
#pragma mark Optional
    NSArray<id<STDSChallengeResponseMessageExtension>> *messageExtensions = [json _stds_arrayForKey:@"messageExtension"
                                                                                   arrayElementType:[STDSChallengeResponseMessageExtensionObject class]
                                                                                           required:NO
                                                                                              error:&error];
    NSMutableArray<NSString *> *unrecognizedMessageExtensionIdentifiers = [NSMutableArray new];
    for (id<STDSChallengeResponseMessageExtension> messageExtension in messageExtensions) {
        if (messageExtension.criticalityIndicator && ![[self supportedMessageExtensions] containsObject:messageExtension.identifier]) {
            [unrecognizedMessageExtensionIdentifiers addObject:messageExtension.identifier];
        }
    }
    if (unrecognizedMessageExtensionIdentifiers.count > 0) {
        error = [NSError errorWithDomain:STDSStripe3DS2ErrorDomain code:STDSErrorCodeUnrecognizedCriticalMessageExtension userInfo:@{STDSStripe3DS2UnrecognizedCriticalMessageExtensionsKey: unrecognizedMessageExtensionIdentifiers}];
    }
    if (messageExtensions.count > 10) {
        error = [NSError _stds_invalidJSONFieldError:@"messageExtension"];
    }
    
    NSString *encodedAcsHTMLRefresh = [json _stds_stringForKey:@"acsHTMLRefresh" required:NO error: &error];
    NSString *acsHTMLRefresh = [encodedAcsHTMLRefresh _stds_base64URLDecodedString];
    if (encodedAcsHTMLRefresh && !acsHTMLRefresh) {
        // html was not valid base64url
        error = [NSError _stds_invalidJSONFieldError:@"acsHTMLRefresh"];
    }
    
    BOOL infoLabelRequired = NO;
    BOOL headerRequired = NO;
    BOOL infoTextRequired = NO;
    switch (acsUIType) {
        case STDSACSUITypeNone:
            break; // no-op
        case STDSACSUITypeText:
        case STDSACSUITypeSingleSelect:
        case STDSACSUITypeMultiSelect:
            infoLabelRequired = YES; // TC_SDK_10270_001 & TC_SDK_10276_001 & TC_SDK_10284_001
            headerRequired = YES; // TC_SDK_10268_001 & TC_SDK_10273_001 & TC_SDK_10282_001
            infoTextRequired = YES; // TC_SDK_10272_001 & TC_SDK_10278_001 & TC_SDK_10286_001
            break;
        case STDSACSUITypeOOB:
            
            break;
        case STDSACSUITypeHTML:
            break; // no-op
    }
    

    NSString *challengeInfoLabel = [json _stds_stringForKey:@"challengeInfoLabel" validator:nil required:infoLabelRequired error:&error];
    NSString *challengeInfoHeader = [json _stds_stringForKey:@"challengeInfoHeader" required: (oobContinueLabel != nil) || headerRequired error:&error]; // TC_SDK_10292_001
    NSString *challengeInfoText =  [json _stds_stringForKey:@"challengeInfoText" required:(oobContinueLabel != nil) || infoTextRequired error:&error]; // TC_SDK_10292_001
    NSString *challengeAdditionalInfoText =  [json _stds_stringForKey:@"challengeAddInfo" required:NO error:&error];
    
    if (acsUIType != STDSACSUITypeHTML) {
        if (!error && submitAuthenticationLabel && (!challengeInfoLabel && !challengeInfoHeader && !challengeInfoText)) {
            error = [NSError _stds_missingJSONFieldError:@"challengeInfoLabel or challengeInfoText or challengeInfoHeader"];
        }
    }
    
    NSString *showChallengeInfoTextIndicatorRawString;
    if (json[@"challengeInfoTextIndicator"]) {
        showChallengeInfoTextIndicatorRawString = [json _stds_stringForKey:@"challengeInfoTextIndicator" validator:^BOOL (NSString *value) {
            return [value isEqualToString:@"N"] || [value isEqualToString:@"Y"];
        } required:NO error:&error];
    }
    BOOL showChallengeInfoTextIndicator = showChallengeInfoTextIndicatorRawString ? showChallengeInfoTextIndicatorRawString.boolValue : NO; // If the field is missing, we shouldn't show the indicator
    NSString *expandInfoLabel = [json _stds_stringForKey:@"expandInfoLabel" required:NO error:&error];
    NSString *expandInfoText = [json _stds_stringForKey:@"expandInfoText" required:NO error:&error];
    NSURL *oobAppURL = [json _stds_urlForKey:@"oobAppURL" required:NO error:&error];
    NSString *oobAppLabel = [json _stds_stringForKey:@"oobAppURL" required:NO error:&error];
    NSDictionary *issuerImageJSON = [json _stds_dictionaryForKey:@"issuerImage" required:NO error:&error];
    STDSChallengeResponseImageObject *issuerImage = [STDSChallengeResponseImageObject decodedObjectFromJSON:issuerImageJSON error:&error];
    NSDictionary *paymentSystemImageJSON = [json _stds_dictionaryForKey:@"psImage" required:NO error:&error];
    STDSChallengeResponseImageObject *paymentSystemImage = [STDSChallengeResponseImageObject decodedObjectFromJSON:paymentSystemImageJSON error:&error];
    NSString *resendInformationLabel = [json _stds_stringForKey:@"resendInformationLabel" required:NO error:&error];
    NSString *whitelistingInfoText = [json _stds_stringForKey:@"whitelistingInfoText" required:NO error:&error];
    if (whitelistingInfoText.length > 64) {
        // TC_SDK_10199_001
        error = [NSError _stds_invalidJSONFieldError:@"whitelisting text is greater than 64 characters"];
    }
    NSString *whyInfoLabel = [json _stds_stringForKey:@"whyInfoLabel" required:NO error:&error];
    NSString *whyInfoText = [json _stds_stringForKey:@"whyInfoText" required:NO error:&error];
    NSString *transactionStatus = [json _stds_stringForKey:@"transStatus" required:challengeCompletionIndicator error:&error];
    
    if (error) {
        if (outError) {
            *outError = error;
        }
        return nil;
    }
    
    return [[self alloc] initWithThreeDSServerTransactionID:threeDSServerTransactionID
                                         acsCounterACStoSDK:acsCounterACStoSDK
                                           acsTransactionID:acsTransactionID
                                                    acsHTML:acsHTML
                                             acsHTMLRefresh:acsHTMLRefresh
                                                  acsUIType:acsUIType
                               challengeCompletionIndicator:challengeCompletionIndicator
                                        challengeInfoHeader:challengeInfoHeader
                                         challengeInfoLabel:challengeInfoLabel
                                          challengeInfoText:challengeInfoText
                                challengeAdditionalInfoText:challengeAdditionalInfoText
                             showChallengeInfoTextIndicator:showChallengeInfoTextIndicator
                                        challengeSelectInfo:challengeSelectInfo
                                            expandInfoLabel:expandInfoLabel
                                             expandInfoText:expandInfoText
                                                issuerImage:issuerImage
                                          messageExtensions:messageExtensions
                                             messageVersion:messageVersion
                                                  oobAppURL:oobAppURL
                                                oobAppLabel:oobAppLabel
                                           oobContinueLabel:oobContinueLabel
                                         paymentSystemImage:paymentSystemImage
                                     resendInformationLabel:resendInformationLabel
                                           sdkTransactionID:sdkTransactionID
                                  submitAuthenticationLabel:submitAuthenticationLabel
                                       whitelistingInfoText:whitelistingInfoText
                                               whyInfoLabel:whyInfoLabel
                                                whyInfoText:whyInfoText
                                          transactionStatus:transactionStatus];
}

@end

NS_ASSUME_NONNULL_END
