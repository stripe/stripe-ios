//
//  STPCategoryLoader.h
//  Stripe
//
//  Created by Jack Flintermann on 10/19/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef STP_STATIC_LIBRARY_BUILD
@interface STPCategoryLoader : NSObject

+ (void)loadCategories;

@end
#endif
