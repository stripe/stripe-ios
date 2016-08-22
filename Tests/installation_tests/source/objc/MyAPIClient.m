//
//  MyAPIClient.m
//  ManualInstallationTest
//
//  Created by Ben Guo on 8/19/16.
//  Copyright © 2016 stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Stripe/Stripe.h>
#import "MyAPIClient.h"

@interface MyAPIClient ()
@property (nonatomic, strong) STPCard *defaultSource;
@property (nonatomic, strong) NSArray<STPCard *> *sources;
@end

@implementation MyAPIClient

- (void)retrieveCustomer:(STPCustomerCompletionBlock)completion {
    STPCustomer *customer = [STPCustomer customerWithStripeID:@"cus_123" defaultSource:nil sources:@[]];
    completion(customer, nil);
}

- (void)attachSourceToCustomer:(id<STPSource>)source completion:(STPErrorBlock)completion {
    if ([source isKindOfClass:[STPToken class]]) {
        self.defaultSource = ((STPToken *)source).card;
    }
    completion(nil);
}

- (void)selectDefaultCustomerSource:(id<STPSource>)source completion:(STPErrorBlock)completion {
    if ([source isKindOfClass:[STPToken class]]) {
        self.defaultSource = ((STPToken *)source).card;
    }
    completion(nil);
}

@end
