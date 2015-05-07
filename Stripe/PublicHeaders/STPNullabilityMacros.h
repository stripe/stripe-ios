//
//  STPNullabilityMacros.h
//  Stripe
//
//  Created by Jack Flintermann on 5/1/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//
//  Based on https://gist.github.com/steipete/d9f519858fe5fb5533eb

#pragma once

#if __has_feature(nullability)
#define STP_ASSUME_NONNULL_BEGIN _Pragma("clang assume_nonnull begin")
#define STP_ASSUME_NONNULL_END _Pragma("clang assume_nonnull end")
#define stp_nullable nullable
#define stp_nonnull nonnull
#define stp_null_unspecified null_unspecified
#define stp_null_resettable null_resettable
#define __stp_nullable __nullable
#define __stp_nonnull __nonnull
#define __stp_null_unspecified __null_unspecified
#else
#define STP_ASSUME_NONNULL_BEGIN
#define STP_ASSUME_NONNULL_END
#define stp_nullable
#define stp_nonnull
#define stp_null_unspecified
#define stp_null_resettable
#define __stp_nullable
#define __stp_nonnull
#define __stp_null_unspecified
#endif
