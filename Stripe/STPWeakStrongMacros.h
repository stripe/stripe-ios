//
//  STPWeakStrongMacros.h
//  Stripe
//
//  Created by Brian Dorfman on 7/28/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#ifndef STPWeakStrongMacros_h
#define STPWeakStrongMacros_h

/*
 * Based on @weakify() and @strongify() from
 * https://github.com/jspahrsummers/libextc
 */

#define WEAK(var) __weak typeof(var) weak_##var = var;
#define STRONG(var) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
__strong typeof(var) self = weak_##var; \
_Pragma("clang diagnostic pop") \

#endif /* STPWeakStrongMacros_h */
