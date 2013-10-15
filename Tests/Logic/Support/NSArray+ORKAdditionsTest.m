//
//  NSArray+ORKAdditionsTest.m
//  RestKit
//
//  Created by Blake Watters on 4/10/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "ORKTestEnvironment.h"
#import "NSArray+ORKAdditions.h"
#import "ORKTestUser.h"

@interface NSArray_ORKAdditionsTest : ORKTestCase
@end

@implementation NSArray_ORKAdditionsTest

#pragma mark - sectionsGroupedByKeyPath Tests

- (void)testReturnsEmptyArrayWhenGroupingEmptyArray
{
    NSArray *objects = [NSArray array];
    assertThat([objects sectionsGroupedByKeyPath:@"whatever"], is(empty()));
}

- (void)testReturnsSingleSectionWhenGroupingSingleObject
{
    ORKTestUser *user = [ORKTestUser new];
    user.name = @"Blake";
    user.country = @"USA";
    NSArray *users = [NSArray arrayWithObject:user];

    NSArray *sections = [users sectionsGroupedByKeyPath:@"country"];
    assertThat(sections, hasCountOf(1));
}

- (void)testReturnsTwoSectionsWhenGroupingThreeObjectsWithTwoUniqueValues
{
    ORKTestUser *user1 = [ORKTestUser new];
    user1.name = @"Blake";
    user1.country = @"USA";

    ORKTestUser *user2 = [ORKTestUser new];
    user2.name = @"Colin";
    user2.country = @"USA";

    ORKTestUser *user3 = [ORKTestUser new];
    user3.name = @"Pepe";
    user3.country = @"Spain";

    NSArray *users = [NSArray arrayWithObjects:user1, user2, user3, nil];

    NSArray *sections = [users sectionsGroupedByKeyPath:@"country"];
    assertThat(sections, hasCountOf(2));
    assertThat([sections objectAtIndex:0], contains(user1, user2, nil));
    assertThat([sections objectAtIndex:1], contains(user3, nil));
}

- (void)testCreationOfSingleSectionForNullValues
{
    ORKTestUser *user1 = [ORKTestUser new];
    user1.name = @"Blake";
    user1.country = @"USA";

    ORKTestUser *user2 = [ORKTestUser new];
    user2.name = @"Expatriate";
    user2.country = nil;

    ORKTestUser *user3 = [ORKTestUser new];
    user3.name = @"John Doe";
    user3.country = nil;

    ORKTestUser *user4 = [ORKTestUser new];
    user4.name = @"Pepe";
    user4.country = @"Spain";

    NSArray *users = [NSArray arrayWithObjects:user1, user2, user3, user4, nil];

    NSArray *sections = [users sectionsGroupedByKeyPath:@"country"];
    assertThat(sections, hasCountOf(3));
    assertThat([sections objectAtIndex:0], contains(user1, nil));
    assertThat([sections objectAtIndex:1], contains(user2, user3, nil));
    assertThat([sections objectAtIndex:2], contains(user4, nil));
}

@end
