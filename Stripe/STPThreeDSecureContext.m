//
//  STPThreeDSecureContext.m
//  Stripe
//
//  Created by Brian Dorfman on 9/29/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPThreeDSecureContext.h"

#import <SafariServices/SafariServices.h>

#import "STPBackendAPIAdapter.h"
#import "STPCard.h"
#import "STPThreeDSecure.h"
#import "STPWeakStrongMacros.h"

NS_ASSUME_NONNULL_BEGIN

typedef BOOL(^STPPaymentConfigThreeDSecureSupportBlock)(STPThreeDSecureConfiguration *config, STPCard *card);
static NSNotificationName const kSTPThreeDSecureContinueFlowNotification = @"kSTPThreeDSecureContinueFlowNotification";
static NSString *const KSTPThreeDSecureContinueFlowNotificationURLKey = @"KSTPThreeDSecureContinueNotificationURLKey";

@interface STPThreeDSecure(Private)
@property (nonatomic, readwrite) BOOL authenticated;
@end

@interface STPThreeDSecureConfiguration ()
@property (nonatomic, readwrite, copy) NSString *threeDSecureReturnUrl;
@property (nonatomic, nullable, copy) STPPaymentConfigThreeDSecureSupportBlock shouldShowThreeDSecureBlock;
@end

@implementation STPThreeDSecureConfiguration

- (instancetype)initWithReturnUrl:(NSString *)returnUrl {
    if ((self = [super init])) {
        self.threeDSecureReturnUrl = returnUrl;
        _threeDSecureSupportLevel = STPThreeDSecureSupportLevelDisabled;
    }
    return self;
}

- (BOOL)shouldRequestThreeDSecureForCard:(STPCard *)card {
    // Using a block here to get around API Extension compatibility.
    // The block is set in setThreeDSecureSupportLevel which is marked as
    // unavailable in app extensions
    if (self.shouldShowThreeDSecureBlock) {
        return self.shouldShowThreeDSecureBlock(self, card);
    }
    else {
        return NO;
    }
}

- (void)setThreeDSecureSupportLevel:(STPThreeDSecureSupportLevel)threeDSecureSupportLevel {
    _threeDSecureSupportLevel = threeDSecureSupportLevel;
    
    // Using a block here to get around API Extension compatibility.
    if (!self.shouldShowThreeDSecureBlock) {  
        self.shouldShowThreeDSecureBlock = ^BOOL (STPThreeDSecureConfiguration *config, STPCard *card) {
            if (config.threeDSecureReturnUrl.length == 0) {
                // TODO: also check that this is a valid url with a registered scheme
                return NO;
            }
            
            switch (config.threeDSecureSupportLevel) {
                case STPThreeDSecureSupportLevelDisabled:
                    return NO;
                case STPThreeDSecureSupportLevelOptional:
                    return (card.threeDSecureSupport != STPCardThreeDSecureSupportTypeNone);
                case STPThreeDSecureSupportLevelRequired:
                    return (card.threeDSecureSupport == STPCardThreeDSecureSupportTypeRequired);
            }
        };
    }
}


@end

@interface STPThreeDSecureContext () <SFSafariViewControllerDelegate>
@property (nonatomic, strong) id<STPBackendAPIAdapter> apiAdapter;
@property (nonatomic, strong) STPThreeDSecureConfiguration *configuration;

@property (nonatomic, nullable, copy) STPThreeDSecureFlowCompletionBlock completion;
@property (nonatomic, nullable, strong) STPThreeDSecure *inProgress3DSecureAuthorization;

@property (nonatomic, nullable, strong) UIViewController *presentedViewController;
@end

@implementation STPThreeDSecureContext

- (instancetype)initWithAPIAdapter:(id<STPBackendAPIAdapter>)apiAdapter 
                     configuration:(STPThreeDSecureConfiguration *)configuration {
    if ((self = [super init])) {
        self.apiAdapter = apiAdapter;
        self.configuration = configuration;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)startThreeDSecureFlowWithParams:(STPThreeDSecureParams *)params
               presentingViewController:(UIViewController *)viewController
                             completion:(STPThreeDSecureFlowCompletionBlock)completion {
    
    self.completion = completion;
    
    WEAK(self);
    STPThreeDSecureCompletionBlock createCompletion = ^(STPThreeDSecure * _Nullable threeDSecure, NSError * _Nullable error) {
        STRONG(self);
        NSURL *redirectURL = [NSURL URLWithString:threeDSecure.redirectURL];
        
        if (error == nil 
            && threeDSecure.threeDSecureId.length > 0
            && redirectURL != nil) {
            [self showRedirectURL:redirectURL
               fromViewController:viewController
                           for3DS:threeDSecure];
        }
        else {
            [self cleanupAndCompleteWithThreeDSecure:threeDSecure
                                           succeeded:NO
                                               error:error];
        }
    };
    
    [self.apiAdapter createThreeDSecureWithParams:params 
                                        returnUrl:self.configuration.threeDSecureReturnUrl
                                       completion:createCompletion];
}

- (void)showRedirectURL:(NSURL *)url 
     fromViewController:(UIViewController *)hostViewController
                 for3DS:(STPThreeDSecure *)threeDSecure {
    self.inProgress3DSecureAuthorization = threeDSecure;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleContinueFlowNotification:) 
                                                 name:kSTPThreeDSecureContinueFlowNotification 
                                               object:nil];
    
    if ([SFSafariViewController class] != nil) {
        SFSafariViewController *safariVC = [[SFSafariViewController alloc] initWithURL:url];
        safariVC.delegate = self;
        self.presentedViewController = safariVC;
        [hostViewController presentViewController:safariVC 
                                         animated:YES 
                                       completion:nil];
    }
    else {
        // TODO: Probably need to flesh out STPWebViewController
    }
}

- (void)handleContinueFlowNotification:(NSNotification *)notification {
    NSURL *url = notification.userInfo[KSTPThreeDSecureContinueFlowNotificationURLKey];
    [self continueThreeDSecureFlowWithURL:url];
}

- (void)continueThreeDSecureFlowWithURL:(nullable NSURL *)url {
    if (url == nil
        || self.inProgress3DSecureAuthorization == nil) {
        [self cleanupAndCompleteWithThreeDSecure:self.inProgress3DSecureAuthorization 
                                       succeeded:NO
                                           error:nil];
    }
    else {
        // TODO: Parse out URL parameters
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url
                                                   resolvingAgainstBaseURL:NO];
        
        NSMutableDictionary <NSString *, NSString *> *queryItems = [NSMutableDictionary new];
        for (NSURLQueryItem *queryItem in components.queryItems) {
            queryItems[queryItem.name] = queryItem.value;
        }
        
        NSString *statusString = queryItems[@"status"];
        NSString *authenticatedString = queryItems[@"authenticated"];
        
//        NSString *errorCodeString = queryItems[@"error_code"];
        // TODO: possible error codes: already_used, cardholder_failed, processing_error
        
        
        BOOL succeeded = [statusString isEqualToString:@"succeeded"];
        BOOL authenticated = [authenticatedString isEqualToString:@"true"];
        self.inProgress3DSecureAuthorization.authenticated = authenticated;
        
        [self cleanupAndCompleteWithThreeDSecure:self.inProgress3DSecureAuthorization 
                                       succeeded:succeeded 
                                           error:nil];
    }
}

- (void)cleanupAndCompleteWithThreeDSecure:(nullable STPThreeDSecure *)threeDSecure
                                 succeeded:(BOOL)succeeded
                                     error:(nullable NSError *)error {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.inProgress3DSecureAuthorization = nil;
    [self.presentedViewController dismissViewControllerAnimated:YES 
                                                     completion:^{
                                                         if (self.completion) {
                                                             self.completion(threeDSecure, succeeded, error);
                                                         }
                                                     }];
    self.completion = nil;
}

- (void)cancelThreeDSecureFlow {
    // nil this out here on the assumption you don't want a completion block
    // if you are manually cancelling
    self.completion = nil;
    
    [self cleanupAndCompleteWithThreeDSecure:self.inProgress3DSecureAuthorization 
                                   succeeded:NO 
                                       error:nil];
}

- (void)safariViewControllerDidFinish:(SFSafariViewController * __unused)controller {
    [self cleanupAndCompleteWithThreeDSecure:self.inProgress3DSecureAuthorization
                                   succeeded:NO 
                                       error:nil];
}

@end

@implementation Stripe (ThreeDSecureAdditions)

+ (void)continueThreeDSecureFlowWithURL:(NSURL *)url {
    NSDictionary *userInfo = nil;
    if (url) {
        userInfo = [NSDictionary dictionaryWithObject:url 
                                               forKey:KSTPThreeDSecureContinueFlowNotificationURLKey];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kSTPThreeDSecureContinueFlowNotification 
                                                        object:nil 
                                                      userInfo:userInfo];
}

@end

NS_ASSUME_NONNULL_END
