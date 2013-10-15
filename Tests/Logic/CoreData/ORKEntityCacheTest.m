//
//  ORKEntityCacheTest.m
//  RestKit
//
//  Created by Blake Watters on 5/2/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "ORKTestEnvironment.h"
#import "NSEntityDescription+ORKAdditions.h"
#import "ORKEntityCache.h"
#import "ORKEntityByAttributeCache.h"
#import "ORKHuman.h"

@interface ORKEntityCacheTest : ORKTestCase
@property (nonatomic, retain) ORKManagedObjectStore *objectStore;
@property (nonatomic, retain) ORKEntityCache *cache;
@property (nonatomic, retain) NSEntityDescription *entity;
@end

@implementation ORKEntityCacheTest

@synthesize objectStore = _objectStore;
@synthesize cache = _cache;
@synthesize entity = _entity;

- (void)setUp
{
    [ORKTestFactory setUp];

    self.objectStore = [ORKTestFactory managedObjectStore];
    _cache = [[ORKEntityCache alloc] initWithManagedObjectContext:self.objectStore.primaryManagedObjectContext];
    self.entity = [ORKHuman entityDescriptionInContext:self.objectStore.primaryManagedObjectContext];
}

- (void)tearDown
{
    self.objectStore = nil;
    self.cache = nil;

    [ORKTestFactory tearDown];
}

- (void)testInitializationSetsManagedObjectContext
{
    assertThat(_cache.managedObjectContext, is(equalTo(self.objectStore.primaryManagedObjectContext)));
}

- (void)testIsEntityCachedByAttribute
{
    assertThatBool([_cache isEntity:self.entity cachedByAttribute:@"railsID"], is(equalToBool(NO)));
    [_cache cacheObjectsForEntity:self.entity byAttribute:@"railsID"];
    assertThatBool([_cache isEntity:self.entity cachedByAttribute:@"railsID"], is(equalToBool(YES)));
}

- (void)testRetrievalOfUnderlyingEntityAttributeCache
{
    [_cache cacheObjectsForEntity:self.entity byAttribute:@"railsID"];
    ORKEntityByAttributeCache *attributeCache = [_cache attributeCacheForEntity:self.entity attribute:@"railsID"];
    assertThat(attributeCache, is(notNilValue()));
}

- (void)testRetrievalOfUnderlyingEntityAttributeCaches
{
    [_cache cacheObjectsForEntity:self.entity byAttribute:@"railsID"];
    NSArray *caches = [_cache attributeCachesForEntity:self.entity];
    assertThat(caches, is(notNilValue()));
    assertThatInteger([caches count], is(equalToInteger(1)));
}

- (void)testRetrievalOfObjectForEntityWithAttributeValue
{
    ORKHuman *human = [ORKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human.railsID = [NSNumber numberWithInteger:12345];
    NSError *error = nil;
    [self.objectStore save:&error];

    [_cache cacheObjectsForEntity:self.entity byAttribute:@"railsID"];
    NSManagedObject *fetchedObject = [self.cache objectForEntity:self.entity withAttribute:@"railsID" value:[NSNumber numberWithInteger:12345]];
    assertThat(fetchedObject, is(notNilValue()));
}

- (void)testRetrievalOfObjectsForEntityWithAttributeValue
{
    ORKHuman *human1 = [ORKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    ORKHuman *human2 = [ORKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    NSError *error = nil;
    [self.objectStore save:&error];

    [_cache cacheObjectsForEntity:self.entity byAttribute:@"railsID"];
    NSArray *objects = [self.cache objectsForEntity:self.entity withAttribute:@"railsID" value:[NSNumber numberWithInteger:12345]];
    assertThat(objects, hasCountOf(2));
    assertThat(objects, containsInAnyOrder(human1, human2, nil));
}

- (void)testThatFlushEmptiesAllUnderlyingAttributeCaches
{
    ORKHuman *human1 = [ORKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    human1.name = @"Blake";
    ORKHuman *human2 = [ORKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    human2.name = @"Sarah";

    [self.objectStore save:nil];
    [_cache cacheObjectsForEntity:self.entity byAttribute:@"railsID"];
    [_cache cacheObjectsForEntity:self.entity byAttribute:@"name"];

    NSArray *objects = [self.cache objectsForEntity:self.entity withAttribute:@"railsID" value:[NSNumber numberWithInteger:12345]];
    assertThat(objects, hasCountOf(2));
    assertThat(objects, containsInAnyOrder(human1, human2, nil));

    objects = [self.cache objectsForEntity:self.entity withAttribute:@"name" value:@"Blake"];
    assertThat(objects, hasCountOf(1));
    assertThat(objects, contains(human1, nil));

    [self.cache flush];
    objects = [self.cache objectsForEntity:self.entity withAttribute:@"railsID" value:[NSNumber numberWithInteger:12345]];
    assertThat(objects, is(empty()));
    objects = [self.cache objectsForEntity:self.entity withAttribute:@"name" value:@"Blake"];
    assertThat(objects, is(empty()));
}

- (void)testAddingObjectAddsToEachUnderlyingEntityAttributeCaches
{
    [_cache cacheObjectsForEntity:self.entity byAttribute:@"railsID"];
    [_cache cacheObjectsForEntity:self.entity byAttribute:@"name"];

    ORKHuman *human1 = [ORKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    human1.name = @"Blake";
    ORKHuman *human2 = [ORKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    human2.name = @"Sarah";

    [_cache addObject:human1];
    [_cache addObject:human2];

    NSArray *objects = [self.cache objectsForEntity:self.entity withAttribute:@"railsID" value:[NSNumber numberWithInteger:12345]];
    assertThat(objects, hasCountOf(2));
    assertThat(objects, containsInAnyOrder(human1, human2, nil));

    objects = [self.cache objectsForEntity:self.entity withAttribute:@"name" value:@"Blake"];
    assertThat(objects, hasCountOf(1));
    assertThat(objects, contains(human1, nil));
}

- (void)testRemovingObjectRemovesFromUnderlyingEntityAttributeCaches
{
    [_cache cacheObjectsForEntity:self.entity byAttribute:@"railsID"];
    [_cache cacheObjectsForEntity:self.entity byAttribute:@"name"];

    ORKHuman *human1 = [ORKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    human1.name = @"Blake";
    ORKHuman *human2 = [ORKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    human2.name = @"Sarah";

    [_cache addObject:human1];
    [_cache addObject:human2];

    NSArray *objects = [self.cache objectsForEntity:self.entity withAttribute:@"railsID" value:[NSNumber numberWithInteger:12345]];
    assertThat(objects, hasCountOf(2));
    assertThat(objects, containsInAnyOrder(human1, human2, nil));

    ORKEntityByAttributeCache *entityAttributeCache = [self.cache attributeCacheForEntity:[ORKHuman entity] attribute:@"railsID"];
    assertThatBool([entityAttributeCache containsObject:human1], is(equalToBool(YES)));
    [self.cache removeObject:human1];
    assertThatBool([entityAttributeCache containsObject:human1], is(equalToBool(NO)));
}

@end
