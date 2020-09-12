//
//  STPAppInfo.h
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/20/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Libraries wrapping the Stripe SDK should use this object to provide information about the library, and set it
 in on `STPAPIClient`.  This information is passed to Stripe so that we can contact you about future issues or critical updates.
 @see https://stripe.com/docs/building-plugins#setappinfo
 */
@interface STPAppInfo : NSObject

/**
 Initializes an instance of `STPAppInfo`.
 
 @param name        The name of your library (e.g. "MyAwesomeLibrary").
 @param partnerId   Your Stripe Partner ID (e.g. "pp_partner_1234").
 @param version     The version of your library (e.g. "1.2.34"). Optional.
 @param url         The website for your library (e.g. "https://myawesomelibrary.info"). Optional.
 */
- (instancetype)initWithName:(NSString *)name
                   partnerId:(NSString *)partnerId
                     version:(nullable NSString *)version
                         url:(nullable NSString *)url;

/**
 Use `initWithName:partnerId:version:url:` instead.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 The name of your library (e.g. "MyAwesomeLibrary").
 */
@property (nonatomic, readonly) NSString *name;

/**
 Your Stripe Partner ID (e.g. "pp_partner_1234").
 */
@property (nonatomic, readonly) NSString *partnerId;

/**
 The version of your library (e.g. "1.2.34").
 */
@property (nonatomic, nullable, readonly) NSString *version;

/**
 The website for your library (e.g. "https://myawesomelibrary.info").
 */
@property (nonatomic, nullable, readonly) NSString *url;

@end

NS_ASSUME_NONNULL_END
