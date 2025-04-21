//
//  STDSChallengeResponseViewController.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/4/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

@import WebKit;

#import "STDSBundleLocator.h"
#import "STDSLocalizedString.h"
#import "STDSChallengeResponseViewController.h"
#import "STDSImageLoader.h"
#import "STDSStackView.h"
#import "STDSBrandingView.h"
#import "STDSChallengeInformationView.h"
#import "STDSChallengeSelectionView.h"
#import "STDSTextChallengeView.h"
#import "STDSVisionSupport.h"
#import "STDSWhitelistView.h"
#import "STDSExpandableInformationView.h"
#import "STDSWebView.h"
#import "STDSProcessingView.h"
#import "UIView+LayoutSupport.h"
#import "NSString+EmptyChecking.h"
#import "UIColor+DefaultColors.h"
#import "UIButton+CustomInitialization.h"
#import "UIFont+DefaultFonts.h"
#import "UIViewController+Stripe3DS2.h"
#import "include/STDSAnalyticsDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface STDSChallengeResponseViewController() <WKNavigationDelegate>

@property (nonatomic, strong, nullable) id<STDSChallengeResponse> response;
@property (nonatomic) STDSDirectoryServer directoryServer;
@property (weak, nonatomic) id<STDSAnalyticsDelegate>analyticsDelegate;
/// Used to track how long we've been showing a loading spinner.  Nil if we are not showing a spinner.
@property (nonatomic, strong, nullable) NSDate *loadingStartDate;
@property (nonatomic, strong, nullable) STDSUICustomization *uiCustomization;
@property (nonatomic, strong) STDSImageLoader *imageLoader;
@property (nonatomic, strong) NSTimer *processingTimer;
@property (nonatomic, getter=isLoading) BOOL loading;
@property (nonatomic, strong) STDSProcessingView *processingView;
@property (nonatomic, strong, nullable) UIScrollView *scrollView;
@property (nonatomic, strong, nullable) STDSWebView *webView;
@property (nonatomic, strong, nullable) STDSChallengeInformationView *challengeInformationView;
@property (nonatomic, strong) UITapGestureRecognizer *tapOutsideKeyboardGestureRecognizer;

// User input views
@property (nonatomic, strong) STDSChallengeSelectionView *challengeSelectionView;
@property (nonatomic, strong) STDSTextChallengeView *textChallengeView;
@property (nonatomic, strong) STDSWhitelistView *whitelistView;
@property (nonatomic, strong) UIStackView *buttonStackView;
@end

@implementation STDSChallengeResponseViewController

static const NSTimeInterval kInterstepProcessingTime = 1.0;
static const NSTimeInterval kDefaultTransitionAnimationDuration = 0.3;
static const CGFloat kBrandingViewHeight = 107;
static const CGFloat kContentHorizontalInset = 16;
static const CGFloat kExpandableContentHorizontalInset = 27;
static const CGFloat kContentViewTopPadding = 16;
static const CGFloat kContentViewBottomPadding = 26;
static const CGFloat kExpandableContentViewTopPadding = 28;

static NSString * const kHTMLStringLoadingURL = @"about:blank";

- (instancetype)initWithUICustomization:(STDSUICustomization * _Nullable)uiCustomization 
                            imageLoader:(STDSImageLoader *)imageLoader
                        directoryServer:(STDSDirectoryServer)directoryServer
                      analyticsDelegate:(nullable id<STDSAnalyticsDelegate>)analyticsDelegate {
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        _uiCustomization = uiCustomization;
        _imageLoader = imageLoader;
        _tapOutsideKeyboardGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_didTapOutsideKeyboard:)];
        _directoryServer = directoryServer;
        _analyticsDelegate = analyticsDelegate;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self _stds_setupNavigationBarElementsWithCustomization:_uiCustomization cancelButtonSelector:@selector(_cancelButtonTapped:)];
    self.view.backgroundColor = self.uiCustomization.backgroundColor;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];

    NSString *imageName = STDSDirectoryServerImageName(self.directoryServer);
    UIImage *dsImage = imageName ? [UIImage imageNamed:imageName inBundle:[STDSBundleLocator stdsResourcesBundle] compatibleWithTraitCollection:nil] : nil;
    self.processingView = [[STDSProcessingView alloc] initWithCustomization:self.uiCustomization directoryServerLogo:dsImage];
    self.processingView.hidden = !self.isLoading;

    [self.view addSubview:self.processingView];
    [self.processingView _stds_pinToSuperviewBoundsWithoutMargin];
    
    [self.view addGestureRecognizer:self.tapOutsideKeyboardGestureRecognizer];
}

#if !STP_TARGET_VISION
- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.uiCustomization.preferredStatusBarStyle;
}
#endif
    
#pragma mark - Public APIs

- (void)setLoading {
    [self _setLoading:YES];
}

- (void)setChallengeResponse:(id<STDSChallengeResponse>)response animated:(BOOL)animated {
    BOOL isFirstChallengeResponse = _response == nil;
    _response = response;
    
    [self.processingTimer invalidate];
    
    if (isFirstChallengeResponse || !self.isLoading || !self.loadingStartDate) {
        [self _displayChallengeResponseAnimated:animated];
    } else {
        // Show the loading spinner for at least kDefaultProcessingTime seconds before displaying
        NSTimeInterval timeSpentLoading = [[NSDate date] timeIntervalSinceDate:self.loadingStartDate];
        if (timeSpentLoading >= kInterstepProcessingTime) {
            // loadingStartDate is nil if we called this method in between viewDidLoad and viewDidAppear.
            // There is no time requirement for the initial CRes.
            [self _displayChallengeResponseAnimated:animated];
        } else {
            self.processingTimer = [NSTimer timerWithTimeInterval:(kInterstepProcessingTime - timeSpentLoading) target:self selector:@selector(_timerDidFire:) userInfo:@(animated) repeats:NO];
            [[NSRunLoop currentRunLoop] addTimer:self.processingTimer forMode:NSDefaultRunLoopMode];
        }
    }
}

- (void)dismiss {
    if (self.presentationDelegate) {
        [self.presentationDelegate dismissChallengeResponseViewController:self];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Private Helpers

- (void)_setLoading:(BOOL)isLoading {
    self.loading = isLoading;
    if (!self.viewLoaded || isLoading == !self.processingView.isHidden) {
        return;
    }
    
    self.navigationItem.rightBarButtonItem.enabled = !isLoading;

    /* According to the specs [0], this should be set to NO during AReq/Ares and YES during CReq/CRes.
     However, according to UL test feedback [1], the AReq/ARes and initial CReq/CRes processing views should be identical.

     [0]: EMV 3-D Secure Protocol and Core Functions Specification v2.1.0 4.2.1.1
     - "The 3DS SDK shall for the CReq/CRes message exchange...[Req 148] Not include the DS logo or any other design element in the Processing screen."
     - "The 3DS SDK shall for the AReq/ARes message exchange...[Req 143] If requested, integrate the DS logo into the Processing screen."
     
     [1]:  UL_PreCompTestReport_ID846_201906_1.0
     - "Visual test case TC_SDK_10022_001 - The test case is FAILED because the processing screen for step 1 and step 2 are not identical. Step 1 displays a 'DS logo' while step 2 does not.
     
     To pass certification, we'll show the DS logo during the initial CReq/CRes (when self.response == nil).
     */
    self.processingView.shouldDisplayDSLogo = self.response == nil;
    // If there's no response, the blur view has nothing to blur and looks better visually if it's just the background color
    // EDIT Jan 2021: The challenge contents is hidden so this never looks good https://jira.corp.stripe.com/browse/MOBILESDK-153
    self.processingView.shouldDisplayBlurView = NO; // self.response != nil;

    if (isLoading) {
        [self.view bringSubviewToFront:self.processingView];
        self.processingView.hidden = NO;
        
        self.loadingStartDate = [NSDate date];
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, STDSLocalizedString(@"Loading", @"Spoken by VoiceOver when the challenge is loading."));
    } else {
        self.processingView.hidden = YES;
        self.loadingStartDate = nil;
    }
}

- (void)_timerDidFire:(NSTimer *)timer {
    BOOL animated = ((NSNumber *)timer.userInfo).boolValue;
    [self.processingTimer invalidate];
    [self _displayChallengeResponseAnimated:animated];
}

- (void)_setupViewHierarchy {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.backgroundColor = self.uiCustomization.footerCustomization.backgroundColor;
    self.scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:self.scrollView];
    [self.scrollView _stds_pinToSuperviewBoundsWithoutMargin];

    STDSStackView *containerStackView = [[STDSStackView alloc] initWithAlignment:STDSStackViewLayoutAxisVertical];
    [self.scrollView addSubview:containerStackView];
    [containerStackView _stds_pinToSuperviewBoundsWithoutMargin];
    
    UIView *contentView = [UIView new];
    contentView.layoutMargins = UIEdgeInsetsMake(kContentViewTopPadding, kContentHorizontalInset, kContentViewBottomPadding, kContentHorizontalInset);
    contentView.backgroundColor = self.uiCustomization.backgroundColor;
    [containerStackView addArrangedSubview:contentView];
    
    STDSStackView *contentStackView = [[STDSStackView alloc] initWithAlignment:STDSStackViewLayoutAxisVertical];
    [contentView addSubview:contentStackView];
    [contentStackView _stds_pinToSuperviewBounds];
    
    STDSBrandingView *brandingView = [self _newConfiguredBrandingView];
    STDSChallengeInformationView *challengeInformationView = [self _newConfiguredChallengeInformationView];
    self.challengeInformationView = challengeInformationView;
    UIButton *actionButton = [self _newConfiguredActionButton];
    UIButton *resendButton = [self _newConfiguredResendButton];
    STDSTextChallengeView *textChallengeView = [self _newConfiguredTextChallengeView];
    self.textChallengeView = textChallengeView;
    STDSChallengeSelectionView *challengeSelectionView = [self _newConfiguredChallengeSelectionView];
    self.challengeSelectionView = challengeSelectionView;
    self.whitelistView = [self _newConfiguredWhitelistView];
    
    UIView *expandableContentView = [UIView new];
    expandableContentView.layoutMargins = UIEdgeInsetsMake(kExpandableContentViewTopPadding, kExpandableContentHorizontalInset, 0, kExpandableContentHorizontalInset);
    [containerStackView addArrangedSubview:expandableContentView];

    STDSStackView *expandableContentStackView = [[STDSStackView alloc] initWithAlignment:STDSStackViewLayoutAxisVertical];
    [expandableContentView addSubview:expandableContentStackView];
    [expandableContentStackView _stds_pinToSuperviewBounds];
    
    STDSExpandableInformationView *whyInformationView = [self _newConfiguredWhyInformationView];
    STDSExpandableInformationView *expandableInformationView = [self _newConfiguredExpandableInformationView];

    [contentStackView addArrangedSubview:brandingView];
    [contentStackView addArrangedSubview:challengeInformationView];
    [contentStackView addArrangedSubview:textChallengeView];
    [contentStackView addArrangedSubview:challengeSelectionView];
    
    self.buttonStackView = [self _newSubmitButtonStackView];
    
    [self.buttonStackView addArrangedSubview:actionButton];
    
    [contentStackView addArrangedSubview:self.buttonStackView];
    
    if (_response.acsUIType != STDSACSUITypeOOB && _response.acsUIType != STDSACSUITypeMultiSelect && _response.acsUIType != STDSACSUITypeSingleSelect) {
        [self.buttonStackView addArrangedSubview:resendButton];
    }
    if (!self.whitelistView.isHidden) {
        [contentStackView addSpacer:10];
    }
    [contentStackView addArrangedSubview:self.whitelistView];
    [expandableContentStackView addArrangedSubview:whyInformationView];
    [expandableContentStackView addArrangedSubview:expandableInformationView];
    
    NSLayoutConstraint *contentViewWidth = [NSLayoutConstraint constraintWithItem:containerStackView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.scrollView attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
    NSLayoutConstraint *brandingViewHeightConstraint = [NSLayoutConstraint constraintWithItem:brandingView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:kBrandingViewHeight];
    [NSLayoutConstraint activateConstraints:@[brandingViewHeightConstraint, contentViewWidth]];
    
    [self _loadBrandingViewImages:brandingView];
}

- (void)_setupWebView {
    self.webView = [[STDSWebView alloc] init];
    self.webView.navigationDelegate = self;
    [self.view addSubview:self.webView];
    [self.webView _stds_pinToSuperviewBounds];
    [self.webView loadExternalResourceBlockingHTMLString:self.response.acsHTML];
}

- (void)_loadBrandingViewImages:(STDSBrandingView *)brandingView {
    NSURL *issuerImageURL = [self _highestFideltyURLFromChallengeResponseImage:self.response.issuerImage];
    
    if (issuerImageURL != nil) {
        [self.imageLoader loadImageFromURL:issuerImageURL completion:^(UIImage * _Nullable image) {
            brandingView.issuerImage = image;
        }];
    }
    
    NSURL *paymentSystemImageURL = [self _highestFideltyURLFromChallengeResponseImage:self.response.paymentSystemImage];
    
    if (paymentSystemImageURL != nil) {
        [self.imageLoader loadImageFromURL:paymentSystemImageURL completion:^(UIImage * _Nullable image) {
            brandingView.paymentSystemImage = image;
        }];
    }
}

- (NSURL * _Nullable)_highestFideltyURLFromChallengeResponseImage:(id <STDSChallengeResponseImage>)image {
    return image.extraHighDensityURL ?: image.highDensityURL ?: image.mediumDensityURL;
}

- (void)_displayChallengeResponseAnimated:(BOOL)animated {
    if (self.response != nil) {
        [self _setLoading:NO];

        UIScrollView *existingScrollView = self.scrollView;
        STDSWebView *existingWebView = self.webView;
        
        void (^transitionBlock)(UIView *, BOOL) = ^void(UIView *viewToTransition, BOOL animated) {
            NSTimeInterval transitionTime = animated ? kDefaultTransitionAnimationDuration : 0;
            viewToTransition.alpha = 0;
            [UIView animateWithDuration:transitionTime animations:^{
                viewToTransition.alpha = 1;
            } completion:^(BOOL finished) {
                [existingScrollView removeFromSuperview];
                [existingWebView removeFromSuperview];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"STDSChallengeResponseViewController.didDisplayChallengeResponse" object:self];
                UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.navigationItem.titleView);
            }];
        };
        
        switch (self.response.acsUIType) {
            case STDSACSUITypeNone:
                break;
            case STDSACSUITypeText:
            case STDSACSUITypeSingleSelect:
            case STDSACSUITypeMultiSelect:
            case STDSACSUITypeOOB:
                [self _setupViewHierarchy];

                transitionBlock(self.scrollView, animated);
                break;
            case STDSACSUITypeHTML:
                [self _setupWebView];

                transitionBlock(self.webView, animated);
                break;
        }
    }
}

- (STDSBrandingView *)_newConfiguredBrandingView {
    STDSBrandingView *brandingView = [[STDSBrandingView alloc] init];
    brandingView.hidden = self.response.issuerImage == nil && self.response.paymentSystemImage == nil;
    
    return brandingView;
}

- (STDSChallengeInformationView *)_newConfiguredChallengeInformationView {
    STDSChallengeInformationView *challengeInformationView = [[STDSChallengeInformationView alloc] init];
    challengeInformationView.headerText = self.response.challengeInfoHeader;
    challengeInformationView.challengeInformationText = self.response.challengeInfoText;
    challengeInformationView.challengeInformationLabel = self.response.challengeInfoLabel;
    challengeInformationView.labelCustomization = self.uiCustomization.labelCustomization;
    
    if (self.response.showChallengeInfoTextIndicator) {
        challengeInformationView.textIndicatorImage = [UIImage imageNamed:@"error" inBundle:[STDSBundleLocator stdsResourcesBundle] compatibleWithTraitCollection:nil];
    }

    return challengeInformationView;
}

- (STDSTextChallengeView *)_newConfiguredTextChallengeView {
    STDSTextChallengeView *textChallengeView = [[STDSTextChallengeView alloc] init];
    textChallengeView.hidden = self.response.acsUIType != STDSACSUITypeText;
    textChallengeView.textFieldCustomization = self.uiCustomization.textFieldCustomization;
    textChallengeView.textField.accessibilityLabel = self.response.challengeInfoLabel;
    textChallengeView.backgroundColor = self.uiCustomization.backgroundColor;
    
    return textChallengeView;
}

- (STDSChallengeSelectionView *)_newConfiguredChallengeSelectionView {
    STDSChallengeSelectionStyle selectionStyle = self.response.acsUIType == STDSACSUITypeMultiSelect ? STDSChallengeSelectionStyleMulti : STDSChallengeSelectionStyleSingle;
    STDSChallengeSelectionView *challengeSelectionView = [[STDSChallengeSelectionView alloc] initWithChallengeSelectInfo:self.response.challengeSelectInfo selectionStyle:selectionStyle];
    challengeSelectionView.hidden = self.response.acsUIType != STDSACSUITypeSingleSelect && self.response.acsUIType != STDSACSUITypeMultiSelect;
    challengeSelectionView.labelCustomization = self.uiCustomization.labelCustomization;
    challengeSelectionView.selectionCustomization = self.uiCustomization.selectionCustomization;
    challengeSelectionView.backgroundColor = self.uiCustomization.backgroundColor;
    
    return challengeSelectionView;
}

- (UIButton *)_newConfiguredActionButton {
    STDSUICustomizationButtonType buttonType = STDSUICustomizationButtonTypeSubmit;
    NSString *buttonTitle;
    
    switch (self.response.acsUIType) {
        case STDSACSUITypeNone:
            break;
        case STDSACSUITypeText:
        case STDSACSUITypeSingleSelect:
        case STDSACSUITypeMultiSelect: {
            buttonTitle = self.response.submitAuthenticationLabel;
            
            break;
        }
        case STDSACSUITypeOOB: {
            buttonType = STDSUICustomizationButtonTypeContinue;
            buttonTitle = self.response.oobContinueLabel;
            
            break;
        }
        case STDSACSUITypeHTML:
            break;
    }
    
    STDSButtonCustomization *buttonCustomization = [self.uiCustomization buttonCustomizationForButtonType:buttonType];
    UIButton *actionButton = [UIButton _stds_buttonWithTitle:buttonTitle customization:buttonCustomization];
    [actionButton addTarget:self action:@selector(_actionButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    actionButton.hidden = buttonTitle == nil || [NSString _stds_isStringEmpty:buttonTitle];
    actionButton.accessibilityIdentifier = @"Continue";

    return actionButton;
}

- (UIButton *)_newConfiguredResendButton {
    STDSButtonCustomization *buttonCustomization = [self.uiCustomization buttonCustomizationForButtonType:STDSUICustomizationButtonTypeResend];
    
    NSString *resendButtonTitle = self.response.resendInformationLabel;
    UIButton *resendButton = [UIButton _stds_buttonWithTitle:resendButtonTitle customization:buttonCustomization];
    
    resendButton.hidden = resendButtonTitle == nil || [NSString _stds_isStringEmpty:resendButtonTitle];
    [resendButton addTarget:self action:@selector(_resendButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    return resendButton;
}

- (STDSWhitelistView *)_newConfiguredWhitelistView {
    STDSWhitelistView *whitelistView = [[STDSWhitelistView alloc] init];
    whitelistView.whitelistText = self.response.whitelistingInfoText;
    whitelistView.labelCustomization = self.uiCustomization.labelCustomization;
    whitelistView.selectionCustomization = self.uiCustomization.selectionCustomization;
    whitelistView.hidden = whitelistView.whitelistText == nil;
    whitelistView.accessibilityIdentifier = @"STDSWhitelistView";
    
    return whitelistView;
}

- (STDSExpandableInformationView *)_newConfiguredWhyInformationView {
    STDSExpandableInformationView *whyInformationView = [[STDSExpandableInformationView alloc] init];
    whyInformationView.title = self.response.whyInfoLabel;
    whyInformationView.text = self.response.whyInfoText;
    whyInformationView.customization = self.uiCustomization.footerCustomization;
    whyInformationView.hidden = whyInformationView.title == nil;
    whyInformationView.backgroundColor = self.uiCustomization.footerCustomization.backgroundColor;
    __weak typeof(self) weakSelf = self;
    whyInformationView.didTap = ^{
        [weakSelf.textChallengeView endEditing:NO];
    };

    return whyInformationView;
}

- (STDSExpandableInformationView *)_newConfiguredExpandableInformationView {
    
    STDSExpandableInformationView *expandableInformationView = [[STDSExpandableInformationView alloc] init];
    expandableInformationView.title = self.response.expandInfoLabel;
    expandableInformationView.text = self.response.expandInfoText;
    expandableInformationView.customization = self.uiCustomization.footerCustomization;
    expandableInformationView.hidden = expandableInformationView.title == nil;
    expandableInformationView.backgroundColor = self.uiCustomization.footerCustomization.backgroundColor;
    __weak typeof(self) weakSelf = self;
    expandableInformationView.didTap = ^{
        [weakSelf.textChallengeView endEditing:NO];
    };

    return expandableInformationView;
}

- (UIStackView *)_newSubmitButtonStackView {
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionFillEqually;
    stackView.alignment = UIStackViewAlignmentFill;
    stackView.spacing = 5;
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    
#if !STP_TARGET_VISION
    CGSize size = [UIScreen mainScreen].bounds.size;
    if (size.width > size.height) {
        // hack to detect landscape
        stackView.axis = UILayoutConstraintAxisHorizontal;
        stackView.alignment = UIStackViewAlignmentCenter;
    }
#endif
    return stackView;
}

- (void)_keyboardDidShow:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];

    // Get the keyboard’s frame at the end of its animation.
    CGRect keyboardFrameEnd = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];

    // Convert the keyboard's frame from the screen's coordinate space to your view's coordinate space.
    keyboardFrameEnd = [self.view convertRect:keyboardFrameEnd fromView:nil];
    
    // Get the intersection between the keyboard's frame and the view's bounds to work with the
    // part of the keyboard that overlaps your view.
    CGRect viewIntersection = CGRectIntersection(self.view.bounds, keyboardFrameEnd);
    CGFloat bottomOffset = 0;

    // Check whether the keyboard intersects your view before adjusting your offset.
    if (!CGRectIsEmpty(viewIntersection)) {
        // Adjust the offset by the difference between the view's height and the height of the
        // intersection rectangle.
        bottomOffset = CGRectGetMaxY(self.view.bounds) - CGRectGetMinY(viewIntersection);
    }

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.scrollView.contentInset.top, 0.0, bottomOffset, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

- (void)_keyboardWillHide:(NSNotification *)notification {
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.scrollView.contentInset.top, 0.0, 0.0, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

- (void)_applicationDidEnterBackground {
    if (self.response.acsUIType == STDSACSUITypeOOB) {
        [self.analyticsDelegate OOBDidEnterBackground:self.response.threeDSServerTransactionID];
    }
}

- (void)_applicationWillEnterForeground:(NSNotification *)notification {
    if (self.response.acsUIType == STDSACSUITypeOOB) {
        
        [self.analyticsDelegate OOBWillEnterForeground:self.response.threeDSServerTransactionID];
        
        if (self.response.challengeAdditionalInfoText) {
            // [Req 316] When Challenge Additional Information Text is present, the SDK would replace the Challenge Information Text and Challenge Information Text Indicator with the Challenge Additional Information Text when the 3DS Requestor App is moved to the foreground.
            self.challengeInformationView.challengeInformationText = self.response.challengeAdditionalInfoText;
            self.challengeInformationView.textIndicatorImage = nil;
        }

        // [REQ 70]
        [self submit:self.response.acsUIType];
    } else if (self.response.acsUIType == STDSACSUITypeHTML && self.response.acsHTMLRefresh) {
        // [Req 317] When the ACS HTML Refresh element is present, the SDK replaces the ACS HTML with the contents of ACS HTML Refresh when the 3DS Requestor App is moved to the foreground.
        [self.webView loadExternalResourceBlockingHTMLString:self.response.acsHTMLRefresh];
    }
}

- (void)_didTapOutsideKeyboard:(UIGestureRecognizer *)gestureRecognizer {
    // Note this doesn't fire if a subview handles the touch (e.g. UIControls, STDSExpandableInformationView)
    [self.textChallengeView endEditing:NO];
}

#pragma mark - Button callbacks

- (void)_cancelButtonTapped:(UIButton *)sender {
    [self.textChallengeView endEditing:NO];
    [self.delegate challengeResponseViewControllerDidCancel:self];
    [self.analyticsDelegate cancelButtonTappedWithTransactionID:self.response.threeDSServerTransactionID];
}

- (void)_resendButtonTapped:(UIButton *)sender {
    [self.textChallengeView endEditing:NO];
    [self.delegate challengeResponseViewControllerDidRequestResend:self];
}

- (void)submit:(STDSACSUIType)type {
    [self.textChallengeView endEditing:NO];

    switch (type) {
        case STDSACSUITypeNone:
            break;
        case STDSACSUITypeText: {
            [self.delegate challengeResponseViewController:self
                                            didSubmitInput:self.textChallengeView.inputText
                                        whitelistSelection:self.whitelistView.selectedResponse];
            
            [self.analyticsDelegate OTPSubmitButtonTappedWithTransactionID:self.response.threeDSServerTransactionID];
            break;
        }
        case STDSACSUITypeSingleSelect:
        case STDSACSUITypeMultiSelect: {
            [self.delegate challengeResponseViewController:self
                                        didSubmitSelection:self.challengeSelectionView.currentlySelectedChallengeInfo
                                        whitelistSelection:self.whitelistView.selectedResponse];
            break;
        }
        case STDSACSUITypeOOB:
            [self.delegate challengeResponseViewControllerDidOOBContinue:self
                                                      whitelistSelection:self.whitelistView.selectedResponse];
            [self.analyticsDelegate OOBContinueButtonTappedWithTransactionID:self.response.threeDSServerTransactionID];
            break;
        case STDSACSUITypeHTML:
            // No action button in this case, see WKNavigationDelegate.
            break;
    }
}

- (void)_actionButtonTapped:(UIButton *)sender {
    [self submit:self.response.acsUIType];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    NSURLRequest *request = navigationAction.request;
    
    if ([request.URL.absoluteString isEqualToString:kHTMLStringLoadingURL]) {
        return decisionHandler(WKNavigationActionPolicyAllow);
    } else {
        if (navigationAction.navigationType == WKNavigationTypeFormSubmitted || navigationAction.navigationType == WKNavigationTypeLinkActivated || navigationAction.navigationType == WKNavigationTypeOther) {
            // When the Cardholder’s response is returned as a parameter string, the form data is passed to the web view instance by triggering a location change to a specified (HTTPS://EMV3DS/challenge) URL with the challenge responses appended to the location URL as query parameters (for example, HTTPS://EMV3DS/challenge?city=Pittsburgh). The web view instance, because it monitors URL changes, receives the Cardholder’s responses as query parameters.
            [self.delegate challengeResponseViewController:self didSubmitHTMLForm:request.URL.query];
        }

        return decisionHandler(WKNavigationActionPolicyCancel);
    }
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    if (size.width > size.height) {
        // hack to detect landscape
        self.buttonStackView.axis = UILayoutConstraintAxisHorizontal;
        self.buttonStackView.alignment = UIStackViewAlignmentCenter;
    } else {
        self.buttonStackView.axis = UILayoutConstraintAxisVertical;
        self.buttonStackView.alignment = UIStackViewAlignmentFill;
    }
}

@end

NS_ASSUME_NONNULL_END
