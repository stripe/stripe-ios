//
//  STPAPIConnection.h
//  Stripe
//
//  Created by Jack Flintermann on 1/8/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^STPAPIConnectionCompletionBlock)(NSURLResponse *response, NSData *body, NSError *requestError);

// Like NSURLConnection but verifies that the server isn't using a revoked certificate.
@interface STPAPIConnection : NSObject<NSURLConnectionDelegate, NSURLConnectionDataDelegate>

- (instancetype)initWithRequest:(NSURLRequest *)request;
- (void)runOnOperationQueue:(NSOperationQueue *)queue completion:(STPAPIConnectionCompletionBlock)handler;

@property (nonatomic) BOOL started;
@property (nonatomic, copy) NSURLRequest *request;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, strong) NSURLResponse *receivedResponse;
@property (nonatomic, strong) NSError *overrideError; // Replaces the request's error
@property (nonatomic, copy) STPAPIConnectionCompletionBlock completionBlock;

// utility methods
+ (NSString *)SHA1FingerprintOfData:(NSData *)data;

@end
