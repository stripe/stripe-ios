//
//  STPRedirectClient.h
//  Stripe
//
//  Created by Brian Dorfman on 1/23/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "STPSource.h"

NS_ASSUME_NONNULL_BEGIN

@class STPSource;
@class STPRedirectConfiguration;

typedef void (^STPRedirectAuthCompletionBlock)(STPSource * __nullable source, NSError * __nullable error);

@interface STPRedirectClient : NSObject
@property (nonatomic, readonly) STPRedirectConfiguration *configuration;
@property (nonatomic, nullable, readonly) STPSource *inProgressAuthSource;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithConfiguration:(STPRedirectConfiguration *)configuration NS_EXTENSION_UNAVAILABLE("Redirect based sources are not available in extensions");

/**
 Starts a new redirect flow authorization for the given source.

 @param source The created source that requires a redirect authorization.
 @param viewController The view controller to present the web view from
 @param completion A block to be called when the redirect flow has completed.
 @return YES if the redirect was started. NO if it could not be started.
 
 @note If you pass in a source which does not support redirect authorization,
 this method will return NO immediately with no effect.

 */
- (BOOL)startRedirectAuthWithSource:(STPSource *)source
           presentingViewController:(UIViewController *)viewController
                         completion:(STPRedirectAuthCompletionBlock)completion;

- (void)cancelCurrentRedirectAuth;

@end

NS_EXTENSION_UNAVAILABLE("Redirect based sources are not available in extensions")
@interface STPRedirectConfiguration : NSObject

/**
 If YES, the redirect URLs will aways open in the standalone Safari app instead
 of attempting to use SFSafariViewController first. 
 
 Defaults to NO.
 */
@property (nonatomic, assign) BOOL alwaysOpenSafari;

@end

NS_ASSUME_NONNULL_END
