//
//  STPAPIConnection.h
//  Stripe
//
//  Created by Jack Flintermann on 1/8/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPNullabilityMacros.h"

typedef void (^STPAPIConnectionCompletionBlock)(NSURLResponse * __stp_nullable response, NSData * __stp_nullable body, NSError * __stp_nullable requestError);

// Like NSURLConnection but verifies that the server isn't using a revoked certificate.
@interface STPAPIConnection : NSObject<NSURLConnectionDelegate, NSURLConnectionDataDelegate>

- (stp_nonnull instancetype)initWithRequest:(stp_nonnull NSURLRequest *)request;
- (void)runOnOperationQueue:(stp_nonnull NSOperationQueue *)queue completion:(stp_nullable STPAPIConnectionCompletionBlock)handler;

@property (nonatomic) BOOL started;
@property (nonatomic, copy, stp_nonnull) NSURLRequest *request;
@property (nonatomic, strong, stp_nullable) NSURLConnection *connection;
@property (nonatomic, strong, stp_nullable) NSMutableData *receivedData;
@property (nonatomic, strong, stp_nullable) NSURLResponse *receivedResponse;
@property (nonatomic, strong, stp_nullable) NSError *overrideError; // Replaces the request's error
@property (nonatomic, copy, stp_nullable) STPAPIConnectionCompletionBlock completionBlock;

@end
