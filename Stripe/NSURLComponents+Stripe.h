//
//  NSURLComponents+Stripe.h
//  Stripe
//
//  Created by Brian Dorfman on 1/26/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLComponents (Stripe)


/**
 Returns or sets self.queryItems as a dictionary where all the keys are the item
 names and the values are the values. When reading, if there are duplicate 
 names, earlier ones are overwritten by later ones.
 */
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *stp_queryItemsDictionary;

/**
 Returns YES if the passed in url matches self in scheme, host, and path,
 AND all the query items in self are also in the passed 
 in components (as determined by `stp_queryItemsDictionary`)
 
 This is used for URL routing style matching

 @param rhsComponents The components to match against
 @return YES if there is a match, NO otherwise.
 */
- (BOOL)stp_matchesURLComponents:(NSURLComponents *)rhsComponents;

@end

void linkNSURLComponentsCategory(void);

NS_ASSUME_NONNULL_END
