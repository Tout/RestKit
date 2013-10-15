//
//  ORKTwitterAppDelegate.m
//  ORKTwitter
//
//  Created by Blake Watters on 9/5/10.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import "ORKTwitterAppDelegate.h"
#import "ORKTwitterViewController.h"
#import "ORKTStatus.h"

@implementation ORKTwitterAppDelegate

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Initialize RestKit
    ORKObjectManager *objectManager = [ORKObjectManager managerWithBaseURLString:@"http://twitter.com"];

    // Enable automatic network activity indicator management
    objectManager.client.requestQueue.showsNetworkActivityIndicatorWhenBusy = YES;

    // Initialize object store
    #ifdef RESTKIT_GENERATE_SEED_DB
        NSString *seedDatabaseName = nil;
        NSString *databaseName = ORKDefaultSeedDatabaseFileName;
    #else
        NSString *seedDatabaseName = ORKDefaultSeedDatabaseFileName;
        NSString *databaseName = @"ORKTwitterData.sqlite";
    #endif

    objectManager.objectStore = [ORKManagedObjectStore objectStoreWithStoreFilename:databaseName usingSeedDatabaseName:seedDatabaseName managedObjectModel:nil delegate:self];

    // Setup our object mappings
    /*!
     Mapping by entity. Here we are configuring a mapping by targetting a Core Data entity with a specific
     name. This allows us to map back Twitter user objects directly onto NSManagedObject instances --
     there is no backing model class!
     */
    ORKManagedObjectMapping *userMapping = [ORKManagedObjectMapping mappingForEntityWithName:@"ORKTUser" inManagedObjectStore:objectManager.objectStore];
    userMapping.primaryKeyAttribute = @"userID";
    [userMapping mapKeyPath:@"id" toAttribute:@"userID"];
    [userMapping mapKeyPath:@"screen_name" toAttribute:@"screenName"];
    [userMapping mapAttributes:@"name", nil];

    /*!
     Map to a target object class -- just as you would for a non-persistent class. The entity is resolved
     for you using the Active Record pattern where the class name corresponds to the entity name within Core Data.
     Twitter status objects will be mapped onto ORKTStatus instances.
     */
    ORKManagedObjectMapping *statusMapping = [ORKManagedObjectMapping mappingForClass:[ORKTStatus class] inManagedObjectStore:objectManager.objectStore];
    statusMapping.primaryKeyAttribute = @"statusID";
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

    // Register our mappings with the provider
    [objectManager.mappingProvider setObjectMapping:statusMapping forResourcePathPattern:@"/status/user_timeline/:username"];

    // Uncomment this to use XML, comment it to use JSON
    //  objectManager.acceptMIMEType = ORKMIMETypeXML;
    //  [objectManager.mappingProvider setMapping:statusMapping forKeyPath:@"statuses.status"];

    // Database seeding is configured as a copied target of the main application. There are only two differences
    // between the main application target and the 'Generate Seed Database' target:
    //  1) RESTKIT_GENERATE_SEED_DB is defined in the 'Preprocessor Macros' section of the build setting for the target
    //      This is what triggers the conditional compilation to cause the seed database to be built
    //  2) Source JSON files are added to the 'Generate Seed Database' target to be copied into the bundle. This is required
    //      so that the object seeder can find the files when run in the simulator.
#ifdef RESTKIT_GENERATE_SEED_DB
    ORKLogConfigureByName("RestKit/ObjectMapping", ORKLogLevelInfo);
    ORKLogConfigureByName("RestKit/CoreData", ORKLogLevelTrace);
    ORKManagedObjectSeeder *seeder = [ORKManagedObjectSeeder objectSeederWithObjectManager:objectManager];

    // Seed the database with instances of ORKTStatus from a snapshot of the RestKit Twitter timeline
    [seeder seedObjectsFromFile:@"restkit.json" withObjectMapping:statusMapping];

    // Seed the database with ORKTUser objects. The class will be inferred via element registration
    [seeder seedObjectsFromFiles:@"users.json", nil];

    // Finalize the seeding operation and output a helpful informational message
    [seeder finalizeSeedingAndExit];

    // NOTE: If all of your mapped objects use keyPath -> objectMapping registration, you can perform seeding in one line of code:
    // [ORKManagedObjectSeeder generateSeedDatabaseWithObjectManager:objectManager fromFiles:@"users.json", nil];
#endif

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
