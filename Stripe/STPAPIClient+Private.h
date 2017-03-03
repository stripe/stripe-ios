//
//  STPAPIClient+Private.h
//  Stripe
//
//  Created by Jack Flintermann on 10/14/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIClient.h"
#import "STPAPIRequest.h"
#import "STPPromise.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPAPIClient()

- (instancetype)initWithPublishableKey:(NSString *)publishableKey
                               baseURL:(NSString *)baseURL;

- (void)createTokenWithData:(NSData *)data
                 completion:(STPTokenCompletionBlock)completion;

- (NSURLSessionDataTask *)retrieveSourceWithId:(NSString *)identifier clientSecret:(NSString *)secret responseCompletion:(STPAPIResponseBlock)completion;

@property (nonatomic, readwrite) NSURL *apiURL;
@property (nonatomic, readonly) STPPromise<NSURLSession*> *urlSessionPromise;

@end

NS_ASSUME_NONNULL_END
