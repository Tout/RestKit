//
//  ORKMacOSXAppDelegate.h
//  ORKMacOSX
//
//  Created by Blake Watters on 4/10/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <RestKit/RestKit.h>

@interface ORKMacOSXAppDelegate : NSObject <NSApplicationDelegate, ORKRequestDelegate>

@property (nonatomic, retain) ORKClient *client;
@property (assign) IBOutlet NSWindow *window;

@end
