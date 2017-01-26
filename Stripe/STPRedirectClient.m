//
//  STPRedirectClient.m
//  Stripe
//
//  Created by Brian Dorfman on 1/23/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPRedirectClient.h"

#import <SafariServices/SafariServices.h>

#import "NSURLComponents+Stripe.h"
#import "STPBlocks.h"
#import "STPURLCallbackHandler.h"

@interface STPRedirectClient () <SFSafariViewControllerDelegate, STPURLCallbackListener>
@property (nonatomic, nullable, copy) STPRedirectAuthCompletionBlock completion;
@property (nonatomic, nullable, strong) UIViewController *presentedViewController;

// To get around app extension restrictions
@property (nonatomic, nullable, copy) void (^openURLBlock)(NSURL *url);
@end

@implementation STPRedirectClient

- (instancetype)initWithConfiguration:(STPRedirectConfiguration *)configuration {
    if ((self = [super init])) {
        _configuration = configuration;
        self.openURLBlock = ^(NSURL *redirectURL){ [[UIApplication sharedApplication] openURL:redirectURL]; };
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)startRedirectAuthWithSource:(STPSource *)source
           presentingViewController:(UIViewController *)presentingViewController
                         completion:(STPRedirectAuthCompletionBlock)completion {
    [self cleanupAndCompleteRedirectWithError:nil];

    if (![self redirectAllowedForSource:source]) {
        return NO;
    }

    self.completion = completion;

    // TODO: STPSource should provide these as named typed NSURLs instead of dictionary lookups
    NSURL *redirectURL = [NSURL URLWithString:source.redirect[@"url"]];
    NSURL *returnURL = [NSURL URLWithString:source.redirect[@"return_url"]];

    // TODO: validate return URL

    _inProgressAuthSource = source;

    [[STPURLCallbackHandler shared] registerListener:self
                                              forURL:returnURL];

    if (!self.configuration.alwaysOpenSafari
        && [SFSafariViewController class] != nil) {
        SFSafariViewController *safariVC = [[SFSafariViewController alloc] initWithURL:redirectURL];
        safariVC.delegate = self;
        self.presentedViewController = safariVC;
        [presentingViewController presentViewController:safariVC
                                               animated:YES
                                             completion:nil];
    }
    else {
        if (self.openURLBlock) {
            self.openURLBlock(redirectURL);
        }
    }

    return YES;
}

- (BOOL)redirectAllowedForSource:(STPSource *)source {
    // TODO: verify that they are valid URLs and that return url is set up correctly
    return ((source.flow == STPSourceFlowRedirect)
            && source.redirect[@"url"] != nil
            && source.redirect[@"return_url"] != nil);
}

- (void)cleanupAndCompleteRedirectWithError:(nullable NSError *)error {
    STPSource *source = self.inProgressAuthSource;

    [[STPURLCallbackHandler shared] unregisterListener:self
                                                forURL:[NSURL URLWithString:source.redirect[@"return_url"]]];


    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated:YES
                                                         completion:^{
                                                             if (self.completion) {
                                                                 self.completion(source, error);
                                                             }
                                                             self.presentedViewController = nil;
                                                         }];
    }
    else {
        if (self.completion) {
            self.completion(source, error);
        }
    }

    _inProgressAuthSource = nil;
    self.completion = nil;

}

- (BOOL)handleURLCallback:(NSURL *)url {
    if (url == nil
        || self.inProgressAuthSource == nil) {
        [self cleanupAndCompleteRedirectWithError:nil];
        return NO;
    }
    else {

        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url
                                                   resolvingAgainstBaseURL:NO];

        NSDictionary <NSString *, NSString *> *queryItems = components.stp_queryItemsDictionary;

        NSString *clientSecretString = queryItems[@"client_secret"];
        NSString *sourceIdString = queryItems[@"source"];

        if ([clientSecretString isEqualToString:self.inProgressAuthSource.clientSecret]
            && [sourceIdString isEqualToString:self.inProgressAuthSource.stripeID]) {

        // TODO: Fetch the source again from the server to get up to date data and then fire completion
            [self cleanupAndCompleteRedirectWithError:nil];
            return YES;
        }
        else {
            return NO;
        }
    }
}

- (void)cancelCurrentRedirectAuth {
    // nil this out here on the assumption you don't want a completion block
    // if you are manually cancelling
    self.completion = nil;

    [self cleanupAndCompleteRedirectWithError:nil];
}

@end

@implementation STPRedirectConfiguration

- (instancetype)init {
    if ((self = [super init])) {
        _alwaysOpenSafari = NO;
    }
    return self;
}

@end
