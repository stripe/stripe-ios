//
//  STDSDebuggerChecker.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 4/8/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSDebuggerChecker.h"

#include <assert.h>
#include <stdbool.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/sysctl.h>

NS_ASSUME_NONNULL_BEGIN

@implementation STDSDebuggerChecker

// This checking code has been lifted from the apple documentation on how to determine if you're attached to a debugger: https://developer.apple.com/library/archive/qa/qa1361/_index.html
+ (BOOL)processIsCurrentlyAttachedToDebugger {
    int                 junk;
    int                 mib[4];
    struct kinfo_proc   info;
    size_t              size;
    
    // Initialize the flags so that, if sysctl fails for some bizarre
    // reason, we get a predictable result.
    
    info.kp_proc.p_flag = 0;
    
    // Initialize mib, which tells sysctl the info we want, in this case
    // we're looking for information about a specific process ID.
    
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = getpid();
    
    // Call sysctl.
    
    size = sizeof(info);
    junk = sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0);
    assert(junk == 0);
    
    // We're being debugged if the P_TRACED flag is set.
    
    return ( (info.kp_proc.p_flag & P_TRACED) != 0 );
}

@end

NS_ASSUME_NONNULL_END
