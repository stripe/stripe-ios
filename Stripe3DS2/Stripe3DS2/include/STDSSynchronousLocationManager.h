//
//  STDSSynchronousLocationManager.h
//  Stripe3DS2
//
//  Created by Cameron Sabol on 1/23/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLLocation;

NS_ASSUME_NONNULL_BEGIN

@interface STDSSynchronousLocationManager : NSObject

+ (instancetype)sharedManager;

+ (BOOL)hasPermissions;

// May be long running. Will return nil on failure or if app lacks permissions
- (nullable CLLocation *)deviceLocation;

@end

NS_ASSUME_NONNULL_END
