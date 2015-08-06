//
//  STPAPIConnection.m
//  Stripe
//
//  Created by Jack Flintermann on 1/8/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import "STPAPIConnection.h"
#import "StripeError.h"
#import <CommonCrypto/CommonDigest.h>

@implementation STPAPIConnection

- (instancetype)initWithRequest:(NSURLRequest *)request {
    if (self = [super init]) {
        _request = request;
        _connection = [[NSURLConnection alloc] initWithRequest:_request delegate:self startImmediately:NO];
        _receivedData = [[NSMutableData alloc] init];
    }
    return self;
}

- (void)runOnOperationQueue:(NSOperationQueue *)queue completion:(STPAPIConnectionCompletionBlock)handler {
    NSCAssert(!self.started, @"This API connection has already started.");
    NSCAssert(queue, @"'queue' is required");
    NSCAssert(handler, @"'handler' is required");
    
    self.started = YES;
    self.completionBlock = handler;
    [self.connection setDelegateQueue:queue];
    [self.connection start];
}

#pragma mark NSURLConnectionDataDelegate

- (void)connection:(__unused NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.receivedResponse = response;
}

- (void)connection:(__unused NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(__unused NSURLConnection *)connection {
    self.connection = nil;
    self.completionBlock(self.receivedResponse, self.receivedData, nil);
    self.receivedData = nil;
    self.receivedResponse = nil;
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(__unused NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.connection = nil;
    self.receivedData = nil;
    self.receivedResponse = nil;
    self.completionBlock(self.receivedResponse, self.receivedData, self.overrideError ?: error);
}

- (void)connection:(__unused NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
        SecTrustResultType resultType;
        SecTrustEvaluate(serverTrust, &resultType);
        [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
    } else if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodDefault]) {
        // If this is an HTTP Authorization request, just continue. We want to bubble this back through the
        // request's error handler.
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
    } else {
        [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
    }
}

@end
