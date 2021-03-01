//
//  STDSChallengeResponseViewController.h
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/4/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STDSChallengeResponse.h"
#import "STDSUICustomization.h"
#import "STDSImageLoader.h"
#import "STDSDirectoryServer.h"

@class STDSChallengeResponseViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol STDSChallengeResponseViewControllerDelegate

/**
 Called when the user taps the Submit button after entering text in the Text flow (STDSACSUITypeText)
 */
- (void)challengeResponseViewController:(STDSChallengeResponseViewController *)viewController didSubmitInput:(NSString *)userInput;

/**
 Called when the user taps the Submit button after selecting one or more options in the Single-Select (STDSACSUITypeSingleSelect) or Multi-Select (STDSACSUITypeMultiSelect) flow.
 */
- (void)challengeResponseViewController:(STDSChallengeResponseViewController *)viewController didSubmitSelection:(NSArray<id<STDSChallengeResponseSelectionInfo>> *)selection;

/**
 Called when the user submits an HTML form.
 */
- (void)challengeResponseViewController:(STDSChallengeResponseViewController *)viewController didSubmitHTMLForm:(NSString *)form;

/**
 Called when the user taps the Continue button from an Out-of-Band flow (STDSACSUITypeOOB).
 */
- (void)challengeResponseViewControllerDidOOBContinue:(STDSChallengeResponseViewController *)viewController;

/**
 Called when the user taps the Cancel button.
 */
- (void)challengeResponseViewControllerDidCancel:(STDSChallengeResponseViewController *)viewController;

/**
 Called when the user taps the Resend button.
 */
- (void)challengeResponseViewControllerDidRequestResend:(STDSChallengeResponseViewController *)viewController;

@end

@protocol STDSChallengeResponseViewControllerPresentationDelegate

- (void)dismissChallengeResponseViewController:(STDSChallengeResponseViewController *)viewController;

@end

@interface STDSChallengeResponseViewController : UIViewController

@property (nonatomic, weak) id<STDSChallengeResponseViewControllerDelegate> delegate;

@property (nonatomic, nullable, weak) id<STDSChallengeResponseViewControllerPresentationDelegate> presentationDelegate;

/// Use setChallengeResponser:animated: to update this value
@property (nonatomic, strong, readonly) id<STDSChallengeResponse> response;

- (instancetype)initWithUICustomization:(STDSUICustomization * _Nullable)uiCustomization imageLoader:(STDSImageLoader *)imageLoader directoryServer:(STDSDirectoryServer)directoryServer;

/// If `setLoading` was called beforehand, this waits until the loading spinner has been shown for at least 1 second before displaying the challenge responseself.processingView.isHidden.
- (void)setChallengeResponse:(id<STDSChallengeResponse>)response animated:(BOOL)animated;

- (void)setLoading;

- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
