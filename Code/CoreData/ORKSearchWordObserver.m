//
//  ORKSearchWordObserver.m
//  RestKit
//
//  Created by Blake Watters on 7/25/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ORKSearchWordObserver.h"
#import "ORKSearchableManagedObject.h"
#import "ORKLog.h"

// Set Logging Component
#undef ORKLogComponent
#define ORKLogComponent lcl_cRestKitCoreDataSearchEngine

static ORKSearchWordObserver *sharedSearchWordObserver = nil;

@implementation ORKSearchWordObserver

+ (ORKSearchWordObserver *)sharedObserver
{
    if (! sharedSearchWordObserver) {
        sharedSearchWordObserver = [[ORKSearchWordObserver alloc] init];
    }

    return sharedSearchWordObserver;
}

- (id)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(managedObjectContextWillSaveNotification:)
                                                     name:NSManagedObjectContextWillSaveNotification
                                                   object:nil];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)managedObjectContextWillSaveNotification:(NSNotification *)notification
{
    NSManagedObjectContext *context = [notification object];
    NSSet *candidateObjects = [[NSSet setWithSet:context.insertedObjects] setByAddingObjectsFromSet:context.updatedObjects];

    ORKLogDebug(@"Managed object context will save notification received. Checking changed and inserted objects for searchable entities...");

    for (NSManagedObject *object in candidateObjects) {
        if (! [object isKindOfClass:[ORKSearchableManagedObject class]]) {
            ORKLogTrace(@"Skipping search words refresh for entity of type '%@': not searchable.", NSStringFromClass([object class]));
            continue;
        }

        NSArray *searchableAttributes = [[object class] searchableAttributes];
        for (NSString *attribute in searchableAttributes) {
            if ([[object changedValues] objectForKey:attribute]) {
                ORKLogDebug(@"Detected change to searchable attribute '%@' for %@ entity: refreshing search words.", attribute, NSStringFromClass([object class]));
                [(ORKSearchableManagedObject *)object refreshSearchWords];
                break;
            }
        }
    }
}

@end
