//
//  STDSChallengeResponse.h
//  Stripe3DS2
//
//  Created by Andrew Harrison on 2/25/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STDSChallengeResponseSelectionInfo.h"
#import "STDSChallengeResponseMessageExtension.h"
#import "STDSChallengeResponseImage.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The `STDSACSUIType` enum defines the type of UI to be presented.
 */
typedef NS_ENUM(NSInteger, STDSACSUIType) {
    
    /// No UI associated with the response.
    STDSACSUITypeNone = 0,
    
    /// Text challenge response UI.
    STDSACSUITypeText = 1,
    
    /// Single-select challenge response UI.
    STDSACSUITypeSingleSelect = 2,
    
    /// Multi-select challenge response UI.
    STDSACSUITypeMultiSelect = 3,
    
    /// Out Of Band challenge response UI.
    STDSACSUITypeOOB = 4,
    
    /// HTML challenge response UI.
    STDSACSUITypeHTML = 5,
};

/// A protocol that represents the information contained within a challenge response.
@protocol STDSChallengeResponse

/// Universally unique transaction identifier assigned by the 3DS Server to identify a single transaction.
@property (nonatomic, readonly) NSString *threeDSServerTransactionID;

/// Counter used as a security measure in the ACS to 3DS SDK secure channel.
@property (nonatomic, readonly) NSString *acsCounterACStoSDK;

/// Universally unique transaction identifier assigned by the ACS to identify a single transaction.
@property (nonatomic, readonly) NSString *acsTransactionID;

/// HTML provided by the ACS in the Challenge Response message. Utilised when HTML is specified in the ACS UI Type during the Cardholder challenge.
@property (nonatomic, readonly, nullable) NSString *acsHTML;

/// Optional HTML provided by the ACS in the CRes message to be utilised in the Out of Band flow when the HTML is specified in the ACS UI Type during the Cardholder challenge, displayed when the app is moved to the foreground.
@property (nonatomic, readonly, nullable) NSString *acsHTMLRefresh;

/// User interface type that the 3DS SDK will render, which includes the specific data mapping and requirements.
@property (nonatomic, readonly) STDSACSUIType acsUIType;

/**
 Indicator of the state of the ACS challenge cycle and whether the challenge has completed or will require additional messages. Shall be populated in all Challenge Response messages to convey the current state of the transaction.
 
 - Note:
 If set to YES, the ACS will populate the Transaction Status in the Challenge Response message.
 */
@property (nonatomic, readonly) BOOL challengeCompletionIndicator;

/// Header text that for the challenge information screen that is being presented.
@property (nonatomic, readonly, nullable) NSString *challengeInfoHeader;

/// Label to modify the Challenge Data Entry field provided by the Issuer.
@property (nonatomic, readonly, nullable) NSString *challengeInfoLabel;

/// Text provided by the ACS/Issuer to Cardholder during the Challenge Message exchange.
@property (nonatomic, readonly, nullable) NSString *challengeInfoText;

/// Text provided by the ACS/Issuer to Cardholder during OOB authentication to replace Challenge Information Text and Challenge Information Text Indicator
@property (nonatomic, readonly, nullable) NSString *challengeAdditionalInfoText;

/// Indicates when the Issuer/ACS would like a warning icon or similar visual indicator to draw attention to the “Challenge Information Text” that is being displayed.
@property (nonatomic, readonly) BOOL showChallengeInfoTextIndicator;

/// Selection information that will be presented to the Cardholder if the option is single or multi-select. The variables will be sent in a JSON Array and parsed by the SDK for display in the user interface.
@property (nonatomic, readonly, nullable) NSArray<id<STDSChallengeResponseSelectionInfo>> *challengeSelectInfo;

/// Label displayed to the Cardholder for the content in Expandable Information Text.
@property (nonatomic, readonly, nullable) NSString *expandInfoLabel;

/// Text provided by the Issuer from the ACS to be displayed to the Cardholder for additional information and the format will be an expandable text field.
@property (nonatomic, readonly, nullable) NSString *expandInfoText;

/// Sent in the initial Challenge Response message from the ACS to the 3DS SDK to provide the URL(s) of the Issuer logo or image to be used in the Native UI.
@property (nonatomic, readonly, nullable) id<STDSChallengeResponseImage> issuerImage;

/// Data necessary to support requirements not otherwise defined in the 3-D Secure message are carried in a Message Extension.
@property (nonatomic, readonly, nullable) NSArray<id<STDSChallengeResponseMessageExtension>> *messageExtensions;

/// Identifies the type of message that is passed.
@property (nonatomic, readonly) NSString *messageType;

/// Protocol version identifier. This shall be the Protocol Version Number of the specification utilised by the system creating this message. The Message Version Number is set by the 3DS Server which originates the protocol with the AReq message. The Message Version Number does not change during a 3DS transaction.
@property (nonatomic, readonly) NSString *messageVersion;

/// Mobile Deep link to an authentication app used in the out-of-band authentication. The App URL will open the appropriate location within the authentication app.
@property (nonatomic, readonly, nullable) NSURL *oobAppURL;

/// Label to be displayed for the link to the OOB App URL. For example: “oobAppLabel”: “Click here to open Your Bank App”
@property (nonatomic, readonly, nullable) NSString *oobAppLabel;

/// Label to be used in the UI for the button that the user selects when they have completed the OOB authentication.
@property (nonatomic, readonly, nullable) NSString *oobContinueLabel;

/// Sent in the initial Challenge Response message from the ACS to the 3DS SDK to provide the URL(s) of the DS or Payment System logo or image to be used in the Native UI.
@property (nonatomic, readonly, nullable) id<STDSChallengeResponseImage> paymentSystemImage;

/// Label to be used in the UI for the button that the user selects when they would like to have the authentication information present.
@property (nonatomic, readonly, nullable) NSString *resendInformationLabel;

/// Universally unique transaction identifier assigned by the 3DS SDK to identify a single transaction.
@property (nonatomic, readonly) NSString *sdkTransactionID;

/**
 Label to be used in the UI for the button that the user selects when they have completed the authentication.
 
 - Note:
 This is not used for OOB authentication.
 */
@property (nonatomic, readonly, nullable) NSString *submitAuthenticationLabel;

/// Text provided by the ACS/Issuer to Cardholder during a Whitelisting transaction. For example, “Would you like to add this Merchant to your whitelist?”
@property (nonatomic, readonly, nullable) NSString *whitelistingInfoText;

/// Label to be displayed to the Cardholder for the "why" information section.
@property (nonatomic, readonly, nullable) NSString *whyInfoLabel;

/// Text provided by the Issuer to be displayed to the Cardholder to explain why the Cardholder is being asked to perform the authentication task.
@property (nonatomic, readonly, nullable) NSString *whyInfoText;

/// Indicates the state of the associated Transaction.
@property (nonatomic, readonly, nullable) NSString *transactionStatus;

@end

NS_ASSUME_NONNULL_END
