//
//  STDSDemoViewController.m
//  Stripe3DS2DemoUI
//
//  Created by Andrew Harrison on 3/11/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSDemoViewController.h"
#import "STDSChallengeResponseViewController.h"
#import "STDSChallengeResponseObject+TestObjects.h"
#import "STDSProgressViewController.h"
#import "STDSStackView.h"
#import "UIView+LayoutSupport.h"
#import "UIColor+ThirteenSupport.h"

NS_ASSUME_NONNULL_BEGIN

@interface STDSDemoViewController () <STDSChallengeResponseViewControllerDelegate>

@property (nonatomic, strong) STDSImageLoader *imageLoader;
@property (nonatomic) BOOL shouldLoadSlowly;
@property (nonatomic) STDSUICustomization *customization;
@property (nonatomic) BOOL isDarkMode;

@end

@implementation STDSDemoViewController

- (instancetype)initWithImageLoader:(STDSImageLoader *)imageLoader {
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        _imageLoader = imageLoader;
        _customization = [STDSUICustomization defaultSettings];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor _stds_systemBackgroundColor];
    
    STDSStackView *containerView = [[STDSStackView alloc] initWithAlignment:STDSStackViewLayoutAxisVertical];
    [self.view addSubview:containerView];
    [containerView _stds_pinToSuperviewBounds];
    
    NSDictionary *buttonTitleToSelectorMapping = @{
                                                   @"Toggle Dark Mode": NSStringFromSelector(@selector(toggleDarkMode)),
                                                   @"Present Text Challenge": NSStringFromSelector(@selector(presentTextChallenge)),
                                                   @"Present Text Challenge With Whitelist": NSStringFromSelector(@selector(presentTextChallengeWithWhitelist)),
                                                   @"Present Text Challenge With Resend": NSStringFromSelector(@selector(presentTextChallengeWithResendCode)),
                                                   @"Present Text Challenge With Whitelist and Resend": NSStringFromSelector(@selector(presentTextChallengeWithResendCodeAndWhitelist)),
                                                   @"Present Text Challenge (loads slowly w/ initial progressView)": NSStringFromSelector(@selector(presentTextChallengeLoadsSlowly)),
                                                   @"Present Single Select Challenge": NSStringFromSelector(@selector(presentSingleSelectChallenge)),
                                                   @"Present Multi Select Challenge": NSStringFromSelector(@selector(presentMultiSelectChallenge)),
                                                   @"Present OOB Challenge": NSStringFromSelector(@selector(presentOOBChallenge)),
                                                   @"Present HTML Challenge": NSStringFromSelector(@selector(presentHTMLChallenge)),
                                                   @"Present Progress View": NSStringFromSelector(@selector(presentProgressView)),
                                                   };
    for (NSString *key in [buttonTitleToSelectorMapping keysSortedByValueUsingComparator:^(NSString *a, NSString *b) {
        return [a compare:b];
    }]) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        [button addTarget:self action:NSSelectorFromString(buttonTitleToSelectorMapping[key]) forControlEvents:UIControlEventTouchUpInside];
        button.titleLabel.numberOfLines = 0;
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        [button setTitle:key forState:UIControlStateNormal];
        [containerView addArrangedSubview:button];
    }
    [containerView addArrangedSubview:[UIView new]];
}

- (void)toggleDarkMode {
    if (self.isDarkMode) {
        self.customization = [STDSUICustomization defaultSettings];
        self.isDarkMode = false;
    } else {
        self.customization = [STDSUICustomization defaultSettings];
        // Navigation bar
        self.customization.navigationBarCustomization = [STDSNavigationBarCustomization new];
        self.customization.navigationBarCustomization.headerText = @"Authentication";
        self.customization.navigationBarCustomization.buttonText = @"Nope";
        self.customization.navigationBarCustomization.textColor = UIColor.whiteColor;
        self.customization.navigationBarCustomization.barStyle = UIBarStyleBlack;

        // General
        self.customization.backgroundColor = UIColor.blackColor;
        self.customization.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        self.customization.preferredStatusBarStyle = UIStatusBarStyleLightContent;
        self.customization.footerCustomization = [STDSFooterCustomization new];
        self.customization.footerCustomization.backgroundColor = [UIColor colorWithRed:.08 green:.08 blue:.08 alpha:1];
        self.customization.footerCustomization.headingFont = [UIFont boldSystemFontOfSize:15];
        self.customization.footerCustomization.headingTextColor = [UIColor colorWithRed:.95 green:.95 blue:.95 alpha:1];
        self.customization.footerCustomization.textColor = [UIColor colorWithRed:.90 green:.90 blue:.90 alpha:1];
        
        // Cancel button
        STDSButtonCustomization *cancelButtonCustomization = [STDSButtonCustomization defaultSettingsForButtonType:STDSUICustomizationButtonTypeCancel];
        cancelButtonCustomization.textColor = UIColor.grayColor;
        cancelButtonCustomization.titleStyle = STDSButtonTitleStyleUppercase;
        [self.customization setButtonCustomization:cancelButtonCustomization forType:STDSUICustomizationButtonTypeCancel];

        // Text
        self.customization.labelCustomization.headingTextColor = UIColor.whiteColor;
        self.customization.labelCustomization.textColor = UIColor.whiteColor;
        
        // Text field
        self.customization.textFieldCustomization.keyboardAppearance = UIKeyboardAppearanceDark;
        self.customization.textFieldCustomization.textColor = UIColor.whiteColor;
        self.customization.textFieldCustomization.borderColor = UIColor.whiteColor;
        
        // Radio/Checkbox
        self.customization.selectionCustomization.secondarySelectedColor = UIColor.lightGrayColor;
        self.customization.selectionCustomization.unselectedBorderColor = UIColor.blackColor;
        self.customization.selectionCustomization.unselectedBackgroundColor = UIColor.darkGrayColor;

        self.isDarkMode = true;
    }
}

- (void)presentTextChallenge {
    [self presentChallengeForChallengeResponse:[STDSChallengeResponseObject textChallengeResponseWithWhitelist:NO resendCode:NO]];
}

- (void)presentTextChallengeWithWhitelist {
    [self presentChallengeForChallengeResponse:[STDSChallengeResponseObject textChallengeResponseWithWhitelist:YES resendCode:NO]];
}

- (void)presentTextChallengeWithResendCode {
    [self presentChallengeForChallengeResponse:[STDSChallengeResponseObject textChallengeResponseWithWhitelist:NO resendCode:YES]];
}

- (void)presentTextChallengeWithResendCodeAndWhitelist {
    [self presentChallengeForChallengeResponse:[STDSChallengeResponseObject textChallengeResponseWithWhitelist:YES resendCode:YES]];
}

- (void)presentTextChallengeLoadsSlowly {
    self.shouldLoadSlowly = YES;
    STDSProgressViewController *progressVC = [[STDSProgressViewController alloc] initWithDirectoryServer:STDSDirectoryServerULTestEC uiCustomization:self.customization didCancel:^{}];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:progressVC];
    [self.navigationController presentViewController:navigationController animated:YES completion:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        [self presentChallengeForChallengeResponse:[STDSChallengeResponseObject textChallengeResponseWithWhitelist:NO resendCode:NO]];
    });

}

- (void)presentSingleSelectChallenge {
    [self presentChallengeForChallengeResponse:[STDSChallengeResponseObject singleSelectChallengeResponse]];
}

- (void)presentMultiSelectChallenge {
    [self presentChallengeForChallengeResponse:[STDSChallengeResponseObject multiSelectChallengeResponse]];
}

- (void)presentOOBChallenge {
    [self presentChallengeForChallengeResponse:[STDSChallengeResponseObject OOBChallengeResponse]];
}

- (void)presentHTMLChallenge {
    [self presentChallengeForChallengeResponse:[STDSChallengeResponseObject HTMLChallengeResponse]];
}

- (void)presentProgressView {
    __weak typeof(self) weakSelf = self;
    UIViewController *vc = [[STDSProgressViewController alloc] initWithDirectoryServer:STDSDirectoryServerULTestEC uiCustomization:self.customization didCancel:^{
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    }];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:vc];
    [self.navigationController presentViewController:navigationController animated:YES completion:nil];
}

- (void)presentChallengeForChallengeResponse:(id<STDSChallengeResponse>)challengeResponse {
    STDSChallengeResponseViewController *challengeResponseViewController = [[STDSChallengeResponseViewController alloc] initWithUICustomization:self.customization imageLoader:self.imageLoader directoryServer:STDSDirectoryServerULTestEC];
    challengeResponseViewController.delegate = self;

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:challengeResponseViewController];
    [self.navigationController presentViewController:navigationController animated:YES completion:nil];
    // Simulate what `STDSTransaction` does
    [challengeResponseViewController setLoading];
    NSUInteger delay = self.shouldLoadSlowly ? 5 : 0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [challengeResponseViewController setChallengeResponse:challengeResponse animated:YES];
    });
}

#pragma mark - STDSChallengeResponseViewControllerDelegate

- (void)challengeResponseViewController:(nonnull STDSChallengeResponseViewController *)viewController didSubmitHTMLForm:(nonnull NSString *)form {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)challengeResponseViewController:(nonnull STDSChallengeResponseViewController *)viewController didSubmitInput:(nonnull NSString *)userInput {
    [viewController setLoading];
    NSUInteger delay = self.shouldLoadSlowly ? 5 : 0;
    self.shouldLoadSlowly = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [viewController setChallengeResponse:[STDSChallengeResponseObject OOBChallengeResponse] animated:YES];
    });
}

- (void)challengeResponseViewController:(nonnull STDSChallengeResponseViewController *)viewController didSubmitSelection:(nonnull NSArray<id<STDSChallengeResponseSelectionInfo>> *)selection {
    [viewController setLoading];
    [viewController setChallengeResponse:[STDSChallengeResponseObject textChallengeResponseWithWhitelist:YES resendCode:YES] animated:YES];
}

- (void)challengeResponseViewControllerDidCancel:(nonnull STDSChallengeResponseViewController *)viewController {
    self.shouldLoadSlowly = NO;
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)challengeResponseViewControllerDidOOBContinue:(nonnull STDSChallengeResponseViewController *)viewController {
    [viewController setLoading];
    [viewController setChallengeResponse:[STDSChallengeResponseObject singleSelectChallengeResponse] animated:YES];
}

- (void)challengeResponseViewControllerDidRequestResend:(nonnull STDSChallengeResponseViewController *)viewController {
}

@end

NS_ASSUME_NONNULL_END
