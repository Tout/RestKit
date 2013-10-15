//
//  ORKTwitterAppDelegate.m
//  ORKTwitter
//
//  Created by Blake Watters on 9/5/10.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <RestKit/RestKit.h>
#import "ORKTwitterAppDelegate.h"
#import "ORKTwitterViewController.h"
#import "ORKTStatus.h"
#import "ORKTUser.h"

@implementation ORKTwitterAppDelegate

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    ORKLogConfigureByName("RestKit/Network*", ORKLogLevelTrace);
    ORKLogConfigureByName("RestKit/ObjectMapping", ORKLogLevelTrace);

    // Initialize RestKit
    ORKObjectManager *objectManager = [ORKObjectManager managerWithBaseURLString:@"http://twitter.com"];

    // Enable automatic network activity indicator management
    objectManager.client.requestQueue.showsNetworkActivityIndicatorWhenBusy = YES;

    // Setup our object mappings
    ORKObjectMapping *userMapping = [ORKObjectMapping mappingForClass:[ORKTUser class]];
    [userMapping mapKeyPath:@"id" toAttribute:@"userID"];
    [userMapping mapKeyPath:@"screen_name" toAttribute:@"screenName"];
    [userMapping mapAttributes:@"name", nil];

    ORKObjectMapping *statusMapping = [ORKObjectMapping mappingForClass:[ORKTStatus class]];
    [statusMapping mapKeyPathsToAttributes:@"id", @"statusID",
     @"created_at", @"createdAt",
     @"text", @"text",
     @"url", @"urlString",
     @"in_reply_to_screen_name", @"inReplyToScreenName",
     @"favorited", @"isFavorited",
     nil];
    [statusMapping mapRelationship:@"user" withMapping:userMapping];

    // Update date format so that we can parse Twitter dates properly
    // Wed Sep 29 15:31:08 +0000 2010
    [ORKObjectMapping addDefaultDateFormatterForString:@"E MMM d HH:mm:ss Z y" inTimeZone:nil];

    // Uncomment these lines to use XML, comment it to use JSON
    //    objectManager.acceptMIMEType = ORKMIMETypeXML;
    //    statusMapping.rootKeyPath = @"statuses.status";

    // Register our mappings with the provider using a resource path pattern
    [objectManager.mappingProvider setObjectMapping:statusMapping forResourcePathPattern:@"/status/user_timeline/:username"];

    // Create Window and View Controllers
    ORKTwitterViewController *viewController = [[[ORKTwitterViewController alloc] initWithNibName:nil bundle:nil] autorelease];
    UINavigationController *controller = [[UINavigationController alloc] initWithRootViewController:viewController];
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    [window addSubview:controller.view];
    [window makeKeyAndVisible];

    return YES;
}

- (void)dealloc
{
    [super dealloc];
}


@end
