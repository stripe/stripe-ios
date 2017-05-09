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
#import "STPBackendAPIAdapter.h" // TODO: remove

NS_ASSUME_NONNULL_BEGIN

@interface STPAPIClient()

@property (nonatomic, readwrite) NSURL *apiURL;
@property (nonatomic, readwrite) NSURLSession *urlSession;

- (instancetype)initWithAPIKey:(NSString *)apiKey NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithPublishableKey:(NSString *)publishableKey
                               baseURL:(NSString *)baseURL;

- (void)createTokenWithParameters:(NSDictionary *)parameters
                       completion:(STPTokenCompletionBlock)completion;

- (NSURLSessionDataTask *)retrieveSourceWithId:(NSString *)identifier clientSecret:(NSString *)secret responseCompletion:(STPAPIResponseBlock)completion;

- (void)retrieveCustomerWithId:(NSString *)identifier completion:(STPCustomerCompletionBlock)completion;

- (void)updateCustomerWithId:(NSString *)customerId
                addingSource:(NSString *)sourceId
                  completion:(STPCustomerCompletionBlock)completion;

- (void)updateCustomerWithId:(NSString *)identifier
                  parameters:(NSDictionary *)parameters
                  completion:(STPCustomerCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
