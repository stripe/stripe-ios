//
//  STDSChallengeResponseObject+TestObjects.m
//  Stripe3DS2DemoUI
//
//  Created by Andrew Harrison on 3/7/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSChallengeResponseObject+TestObjects.h"
#import "STDSChallengeResponseSelectionInfoObject.h"
#import "STDSChallengeResponseImageObject.h"

@implementation STDSChallengeResponseObject (TestObjects)

+ (id<STDSChallengeResponse>)textChallengeResponseWithWhitelist:(BOOL)whitelist resendCode:(BOOL)resendCode {
    return [[STDSChallengeResponseObject alloc] initWithThreeDSServerTransactionID:@""
                                                                acsCounterACStoSDK:@""
                                                                  acsTransactionID:@""
                                                                           acsHTML:nil
                                                                    acsHTMLRefresh:nil
                                                                         acsUIType:STDSACSUITypeText
                                                      challengeCompletionIndicator:NO
                                                               challengeInfoHeader:@"Verify by phone"
                                                                challengeInfoLabel:@"Enter your 6 digit code:"
                                                                 challengeInfoText:@"Great! We have sent you a text message with secure code to your registered mobile phone number.\n\nSent to a number ending in •••• •••• 4729."
                                                       challengeAdditionalInfoText:nil
                                                    showChallengeInfoTextIndicator:NO
                                                               challengeSelectInfo:nil
                                                                   expandInfoLabel:@"Expand Info Label"
                                                                    expandInfoText:@"This field displays expandable information text provided by the ACS."
                                                                       issuerImage:[self issuerImage]
                                                                 messageExtensions:nil
                                                                    messageVersion:@""
                                                                         oobAppURL:nil
                                                                       oobAppLabel:nil
                                                                  oobContinueLabel:nil
                                                                paymentSystemImage:[self paymentImage]
                                                            resendInformationLabel:resendCode ? @"Resend code" : nil
                                                                  sdkTransactionID:@""
                                                         submitAuthenticationLabel:@"Submit"
                                                              whitelistingInfoText:whitelist ? @"Would you like to add this Merchant to your whitelist?" : nil
                                                                      whyInfoLabel:@"Learn more about authentication"
                                                                       whyInfoText:@"This is additional information about authentication. You are being provided extra information you wouldn't normally see, because you've tapped on the above label."
                                                                 transactionStatus:nil];
}

+ (id<STDSChallengeResponse>)singleSelectChallengeResponse {
    STDSChallengeResponseSelectionInfoObject *infoObject1 = [[STDSChallengeResponseSelectionInfoObject alloc] initWithName:@"Mobile" value:@"***-***-*321"];
    STDSChallengeResponseSelectionInfoObject *infoObject2 = [[STDSChallengeResponseSelectionInfoObject alloc] initWithName:@"Email" value:@"a******3@g****.com"];

    return [[STDSChallengeResponseObject alloc] initWithThreeDSServerTransactionID:@""
                                                                acsCounterACStoSDK:@""
                                                                  acsTransactionID:@""
                                                                           acsHTML:nil
                                                                    acsHTMLRefresh:nil
                                                                         acsUIType:STDSACSUITypeSingleSelect
                                                      challengeCompletionIndicator:NO
                                                               challengeInfoHeader:@"Payment Security"
                                                                challengeInfoLabel:nil
                                                                 challengeInfoText:@"Hi Steve, your online payment is being secured using Card Network. Please select the location you would like to receive the code from YourBank."
                                                       challengeAdditionalInfoText:nil
                                                    showChallengeInfoTextIndicator:NO
                                                               challengeSelectInfo:@[infoObject1, infoObject2]
                                                                   expandInfoLabel:@"Need some help?"
                                                                    expandInfoText:@"You've indicated that you need help! We'd be happy to assist with that, by providing helpful text here that makes sense in context."
                                                                       issuerImage:nil
                                                                 messageExtensions:nil
                                                                    messageVersion:@""
                                                                         oobAppURL:nil
                                                                       oobAppLabel:nil
                                                                  oobContinueLabel:nil
                                                                paymentSystemImage:nil
                                                            resendInformationLabel:nil
                                                                  sdkTransactionID:@""
                                                         submitAuthenticationLabel:@"Next"
                                                              whitelistingInfoText:nil
                                                                      whyInfoLabel:@"Learn more about authentication"
                                                                       whyInfoText:@"This is additional information about authentication. You are being provided extra information you wouldn't normally see, because you've tapped on the above label."
                                                                 transactionStatus:nil];
}

+ (id<STDSChallengeResponse>)multiSelectChallengeResponse {
    STDSChallengeResponseSelectionInfoObject *infoObject1 = [[STDSChallengeResponseSelectionInfoObject alloc] initWithName:@"Option1" value:@"Chicago, Illinois"];
    STDSChallengeResponseSelectionInfoObject *infoObject2 = [[STDSChallengeResponseSelectionInfoObject alloc] initWithName:@"Option2" value:@"Portland, Oregon"];
    STDSChallengeResponseSelectionInfoObject *infoObject3 = [[STDSChallengeResponseSelectionInfoObject alloc] initWithName:@"Option3" value:@"Dallas, Texas"];
    STDSChallengeResponseSelectionInfoObject *infoObject4 = [[STDSChallengeResponseSelectionInfoObject alloc] initWithName:@"Option4" value:@"St Louis, Missouri"];

    return [[STDSChallengeResponseObject alloc] initWithThreeDSServerTransactionID:@""
                                                                acsCounterACStoSDK:@""
                                                                  acsTransactionID:@""
                                                                           acsHTML:nil
                                                                    acsHTMLRefresh:nil
                                                                         acsUIType:STDSACSUITypeMultiSelect
                                                      challengeCompletionIndicator:NO
                                                               challengeInfoHeader:@"Payment Security"
                                                                challengeInfoLabel:@"Question 2: What cities have you lived in?"
                                                                 challengeInfoText:@"Please answer 3 security questions from YourBank to complete your payment.\n\nSelect all that apply."
                                                       challengeAdditionalInfoText:nil
                                                    showChallengeInfoTextIndicator:NO
                                                               challengeSelectInfo:@[infoObject1, infoObject2, infoObject3, infoObject4]
                                                                   expandInfoLabel:nil
                                                                    expandInfoText:nil
                                                                       issuerImage:nil
                                                                 messageExtensions:nil
                                                                    messageVersion:@""
                                                                         oobAppURL:nil
                                                                       oobAppLabel:nil
                                                                  oobContinueLabel:nil
                                                                paymentSystemImage:nil
                                                            resendInformationLabel:nil
                                                                  sdkTransactionID:@""
                                                         submitAuthenticationLabel:@"Next"
                                                              whitelistingInfoText:nil
                                                                      whyInfoLabel:@"Learn more about authentication"
                                                                       whyInfoText:@"This is additional information about authentication. You are being provided extra information you wouldn't normally see, because you've tapped on the above label."
                                                                 transactionStatus:nil];
}

+ (id<STDSChallengeResponse>)OOBChallengeResponse {
    return [[STDSChallengeResponseObject alloc] initWithThreeDSServerTransactionID:@""
                                                                acsCounterACStoSDK:@""
                                                                  acsTransactionID:@""
                                                                           acsHTML:nil
                                                                    acsHTMLRefresh:nil
                                                                         acsUIType:STDSACSUITypeOOB
                                                      challengeCompletionIndicator:NO
                                                               challengeInfoHeader:@"Payment Security"
                                                                challengeInfoLabel:nil
                                                                 challengeInfoText:@"For added security, you will be authenticated with YourBank application.\n\nStep 1 - Open your YourBank application directly from your phone and verify this payment.\n\nStep 2 - Tap continue after you have completed authentication with your YourBank application."
                                                       challengeAdditionalInfoText:nil
                                                    showChallengeInfoTextIndicator:YES
                                                               challengeSelectInfo:nil
                                                                   expandInfoLabel:@"Need some help?"
                                                                    expandInfoText:@"You've indicated that you need help! We'd be happy to assist with that, by providing helpful text here that makes sense in context."
                                                                       issuerImage:[self issuerImage]
                                                                 messageExtensions:nil
                                                                    messageVersion:@""
                                                                         oobAppURL:nil
                                                                       oobAppLabel:nil
                                                                  oobContinueLabel:@"Continue"
                                                                paymentSystemImage:[self paymentImage]
                                                            resendInformationLabel:nil
                                                                  sdkTransactionID:@""
                                                         submitAuthenticationLabel:nil
                                                              whitelistingInfoText:nil
                                                                      whyInfoLabel:@"Learn more about authentication"
                                                                       whyInfoText:@"This is additional information about authentication. You are being provided extra information you wouldn't normally see, because you've tapped on the above label."
                                                                 transactionStatus:nil];
}

+ (id<STDSChallengeResponse>)HTMLChallengeResponse {
    NSString *htmlFilePath = [[NSBundle mainBundle] pathForResource:@"acs_challenge" ofType:@"html"];
    NSString *html = [NSString stringWithContentsOfFile:htmlFilePath encoding:NSUTF8StringEncoding error:nil];
    return [[STDSChallengeResponseObject alloc] initWithThreeDSServerTransactionID:@""
                                                                acsCounterACStoSDK:@""
                                                                  acsTransactionID:@""
                                                                           acsHTML:html
                                                                    acsHTMLRefresh:nil
                                                                         acsUIType:STDSACSUITypeHTML
                                                      challengeCompletionIndicator:NO
                                                               challengeInfoHeader:nil
                                                                challengeInfoLabel:nil
                                                                 challengeInfoText:nil
                                                       challengeAdditionalInfoText:nil
                                                    showChallengeInfoTextIndicator:NO
                                                               challengeSelectInfo:nil
                                                                   expandInfoLabel:nil
                                                                    expandInfoText:nil
                                                                       issuerImage:nil
                                                                 messageExtensions:nil
                                                                    messageVersion:@""
                                                                         oobAppURL:nil
                                                                       oobAppLabel:nil
                                                                  oobContinueLabel:nil
                                                                paymentSystemImage:nil
                                                            resendInformationLabel:nil
                                                                  sdkTransactionID:@""
                                                         submitAuthenticationLabel:nil
                                                              whitelistingInfoText:nil
                                                                      whyInfoLabel:nil
                                                                       whyInfoText:nil
                                                                 transactionStatus:nil];
}

+ (id<STDSChallengeResponseImage>)issuerImage {
    return [[STDSChallengeResponseImageObject alloc] initWithMediumDensityURL:[NSURL URLWithString:@"https://via.placeholder.com/150.png?text=150+ISSUER"]
                                                               highDensityURL:[NSURL URLWithString:@"https://via.placeholder.com/300.png?text=300+ISSUER"]
                                                          extraHighDensityURL:[NSURL URLWithString:@"https://via.placeholder.com/450.png?text=450+ISSUER"]];
}

+ (id<STDSChallengeResponseImage>)paymentImage {
    return [[STDSChallengeResponseImageObject alloc] initWithMediumDensityURL:[NSURL URLWithString:@"https://via.placeholder.com/150.png?text=150+PAYMENT"]
                                                               highDensityURL:[NSURL URLWithString:@"https://via.placeholder.com/300.png?text=300+PAYMENT"]
                                                          extraHighDensityURL:[NSURL URLWithString:@"https://via.placeholder.com/450.png?text=450+PAYMENT"]];
}

@end
