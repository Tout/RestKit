//
//  ORKMacOSXAppDelegate.m
//  ORKMacOSX
//
//  Created by Blake Watters on 4/10/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "ORKMacOSXAppDelegate.h"

@implementation ORKMacOSXAppDelegate

@synthesize client = _client;
@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Initialize RestKit
    self.client = [ORKClient clientWithBaseURL:[ORKURL URLWithBaseURLString:@"http://twitter.com"]];
    [self.client get:@"/status/user_timeline/RestKit.json" delegate:self];
}

- (void)request:(ORKRequest *)request didLoadResponse:(ORKResponse *)response
{
    NSLog(@"Loaded JSON: %@", [response bodyAsString]);
}

- (void)dealloc
{
    [super dealloc];
}

@end
