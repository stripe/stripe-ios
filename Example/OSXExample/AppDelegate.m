//
//  AppDelegate.m
//  OSXExample
//
//  Created by Jack Flintermann on 12/17/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import "AppDelegate.h"
#import "ExampleWindowController.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property ExampleWindowController *windowController;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.windowController = [[ExampleWindowController alloc] initWithWindowNibName:@"ExampleWindowController"];
    [self.windowController showWindow:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
