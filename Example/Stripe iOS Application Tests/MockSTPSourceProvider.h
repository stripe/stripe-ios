//
//  MockSTPSourceProvider.h
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 3/29/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Stripe/STPSourceProvider.h>

@interface MockSTPSourceProvider : NSObject

@property(nonatomic, nullable)NSArray<id<STPSource>>* sources;
@property(nonatomic, nullable)id<STPSource> selectedSource;

/// If set, the appropriate functions will complete with these errors
@property(nonatomic, nullable)NSError *retrieveSourcesError;
@property(nonatomic, nullable)NSError *addSourceError;
@property(nonatomic, nullable)NSError *selectSourceError;

@end
