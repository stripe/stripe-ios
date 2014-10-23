//
//  STPTestCardStore.h
//  StripeExample
//
//  Created by Jack Flintermann on 9/30/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000

#import <Foundation/Foundation.h>
#import "STPTestDataStore.h"

@interface STPTestCardStore : NSObject <STPTestDataStore>
@end

#endif