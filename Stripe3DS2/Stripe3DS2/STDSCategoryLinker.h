//
//  STDSCategoryLinker.h
//  Stripe3DS2
//
//  Created by David Estes on 11/18/20.
//  Copyright © 2020 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface STDSCategoryLinker : NSObject

/// This will reference all categories in Stripe3DS2 so the linker doesn't consider them unused code. This should make it so users don't need to add the `-ObjC` linker flag.
+ (void)referenceAllCategories;

@end

NS_ASSUME_NONNULL_END
