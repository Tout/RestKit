//
//  ORKInMemoryManagedObjectCache.m
//  RestKit
//
//  Created by Jeff Arena on 1/24/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "ORKInMemoryManagedObjectCache.h"
#import "NSEntityDescription+ORKAdditions.h"
#import "ORKEntityCache.h"
#import "ORKLog.h"

// Set Logging Component
#undef ORKLogComponent
#define ORKLogComponent lcl_cRestKitCoreData

static NSString * const ORKInMemoryObjectManagedObjectCacheThreadDictionaryKey = @"ORKInMemoryObjectManagedObjectCacheThreadDictionaryKey";

@implementation ORKInMemoryManagedObjectCache

- (ORKEntityCache *)cacheForEntity:(NSEntityDescription *)entity inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NSAssert(entity, @"Cannot find existing managed object without a target class");
    NSAssert(managedObjectContext, @"Cannot find existing managed object with a context");
    NSMutableDictionary *contextDictionary = [[[NSThread currentThread] threadDictionary] objectForKey:ORKInMemoryObjectManagedObjectCacheThreadDictionaryKey];
    if (! contextDictionary) {
        contextDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
        [[[NSThread currentThread] threadDictionary] setObject:contextDictionary forKey:ORKInMemoryObjectManagedObjectCacheThreadDictionaryKey];
    }
    NSNumber *hashNumber = [NSNumber numberWithUnsignedInteger:[managedObjectContext hash]];
    ORKEntityCache *entityCache = [contextDictionary objectForKey:hashNumber];
    if (! entityCache) {
        ORKLogInfo(@"Creating thread-local entity cache for managed object context: %@", managedObjectContext);
        entityCache = [[ORKEntityCache alloc] initWithManagedObjectContext:managedObjectContext];
        [contextDictionary setObject:entityCache forKey:hashNumber];
        [entityCache release];
    }

    return entityCache;
}

- (NSManagedObject *)findInstanceOfEntity:(NSEntityDescription *)entity
                  withPrimaryKeyAttribute:(NSString *)primaryKeyAttribute
                                    value:(id)primaryKeyValue
                   inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    ORKEntityCache *entityCache = [self cacheForEntity:entity inManagedObjectContext:managedObjectContext];
    if (! [entityCache isEntity:entity cachedByAttribute:primaryKeyAttribute]) {
        ORKLogInfo(@"Caching instances of Entity '%@' by primary key attribute '%@'", entity.name, primaryKeyAttribute);
        [entityCache cacheObjectsForEntity:entity byAttribute:primaryKeyAttribute];
        ORKEntityByAttributeCache *attributeCache = [entityCache attributeCacheForEntity:entity attribute:primaryKeyAttribute];
        ORKLogTrace(@"Cached %ld objects", (long)[attributeCache count]);
    }

    return [entityCache objectForEntity:entity withAttribute:primaryKeyAttribute value:primaryKeyValue];
}

- (void)didFetchObject:(NSManagedObject *)object
{
    ORKEntityCache *entityCache = [self cacheForEntity:object.entity inManagedObjectContext:object.managedObjectContext];
    [entityCache addObject:object];
}

- (void)didCreateObject:(NSManagedObject *)object
{
    ORKEntityCache *entityCache = [self cacheForEntity:object.entity inManagedObjectContext:object.managedObjectContext];
    [entityCache addObject:object];
}

- (void)didDeleteObject:(NSManagedObject *)object
{
    ORKEntityCache *entityCache = [self cacheForEntity:object.entity inManagedObjectContext:object.managedObjectContext];
    [entityCache removeObject:object];
}

@end
