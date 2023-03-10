//
//  STDSIPAddress.m
//  Stripe3DS2
//
//  Created by Cameron Sabol on 1/23/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSIPAddress.h"

#include <ifaddrs.h>
#include <arpa/inet.h>

// source: https://zachwaugh.com/posts/programmatically-retrieving-ip-address-of-iphone
NSString * STDSCurrentDeviceIPAddress(void) {
    NSString *address = nil;
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;

    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if( temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }

            temp_addr = temp_addr->ifa_next;
        }
    }

    // Free memory
    freeifaddrs(interfaces);

    return address;
}
