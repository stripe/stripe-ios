//
//  STDSChallengeResponseObject.h
//  Stripe3DS2
//
//  Created by Andrew Harrison on 2/25/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STDSChallengeResponse.h"
#import "STDSJSONDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/// An object used to represent a challenge response from the ACS.
@interface STDSChallengeResponseObject: NSObject <STDSChallengeResponse, STDSJSONDecodable>

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
                                 transactionStatus:(NSString * _Nullable)transactionStatus;
@end

NS_ASSUME_NONNULL_END
