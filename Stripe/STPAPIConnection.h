//
//  STPAPIConnection.h
//  Stripe
//
//  Created by Phil Cohen on 4/9/14.
//

#import <Foundation/Foundation.h>

typedef void (^APIConnectionCompletionBlock)(NSURLResponse *response, NSData *body, NSError *requestError);

// Like NSURLConnection but verifies that the server isn't using a revoked certificate.
@interface STPAPIConnection : NSObject

- (instancetype)initWithRequest:(NSURLRequest *)request NS_DESIGNATED_INITIALIZER;

- (void)runOnOperationQueue:(NSOperationQueue *)queue completion:(APIConnectionCompletionBlock)handler;

@end
