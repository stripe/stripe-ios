//
//  STPAPIConnection.h
//  Stripe
//
//  Created by Jack Flintermann on 1/8/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

@import Foundation;



typedef void (^STPAPIConnectionCompletionBlock)(NSURLResponse * __nullable response, NSData * __nullable body, NSError * __nullable requestError);

// Like NSURLConnection but verifies that the server isn't using a revoked certificate.
@interface STPAPIConnection : NSObject<NSURLConnectionDelegate, NSURLConnectionDataDelegate>

- (nonnull instancetype)initWithRequest:(nonnull NSURLRequest *)request;
- (void)runOnOperationQueue:(nonnull NSOperationQueue *)queue completion:(nullable STPAPIConnectionCompletionBlock)handler;

@property (nonatomic) BOOL started;
@property (nonatomic, copy, nonnull) NSURLRequest *request;
@property (nonatomic, strong, nullable) NSURLConnection *connection;
@property (nonatomic, strong, nullable) NSMutableData *receivedData;
@property (nonatomic, strong, nullable) NSURLResponse *receivedResponse;
@property (nonatomic, strong, nullable) NSError *overrideError; // Replaces the request's error
@property (nonatomic, copy, nullable) STPAPIConnectionCompletionBlock completionBlock;

@end
