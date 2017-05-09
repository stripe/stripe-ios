//
//  STPDropInAPIClient.h
//  Stripe
//
//  Created by Ben Guo on 5/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol STPDropInConfigurationProvider;

@interface STPDropInAPIClient : NSObject

- (instancetype)initWithConfigurationProvider:(id<STPDropInConfigurationProvider>)provider;

@end
