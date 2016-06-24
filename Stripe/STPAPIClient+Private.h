//
//  STPAPIClient+Private.h
//  Stripe
//
//  Created by Jack Flintermann on 10/14/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPAnalyticsClient.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPAPIClient ()<NSURLSessionDelegate>

- (void)createTokenWithData:(NSData *)data
                  tokenType:(STPTokenType)tokenType
                 completion:(nullable STPTokenCompletionBlock)completion;

- (instancetype)initWithPublishableKey:(NSString *)publishableKey
                               baseURL:(NSString *)baseURL;

@property (nonatomic, readwrite) NSURL *apiURL;
@property (nonatomic, readwrite) NSURLSession *urlSession;

@end

NS_ASSUME_NONNULL_END
