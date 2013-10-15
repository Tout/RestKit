//
//  ORKTableViewCellMappingsTest.m
//  RestKit
//
//  Created by Blake Watters on 8/9/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "ORKTestEnvironment.h"
#import "ORKTableViewCellMappings.h"
#import "ORKTestUser.h"
#import "ORKTestAddress.h"

@interface ORKTestSubclassedUser : ORKTestUser
@end
@implementation ORKTestSubclassedUser
@end

@interface ORKTableViewCellMappingsTest : ORKTestCase

@end

@implementation ORKTableViewCellMappingsTest

- (void)testRaiseAnExceptionWhenAnAttemptIsMadeToRegisterAnExistingMappableClass
{
    ORKTableViewCellMappings *cellMappings = [ORKTableViewCellMappings cellMappings];
    ORKTableViewCellMapping *firstMapping = [ORKTableViewCellMapping cellMapping];
    ORKTableViewCellMapping *secondMapping = [ORKTableViewCellMapping cellMapping];
    [cellMappings setCellMapping:firstMapping forClass:[ORKTestUser class]];
    NSException *exception = nil;
    @try {
        [cellMappings setCellMapping:secondMapping forClass:[ORKTestUser class]];
    }
    @catch (NSException *e) {
        exception = e;
    }
    @finally {
        assertThat(exception, is(notNilValue()));
    }
}

- (void)testFindCellMappingsWithAnExactClassMatch
{
    ORKTableViewCellMappings *cellMappings = [ORKTableViewCellMappings cellMappings];
    ORKTableViewCellMapping *firstMapping = [ORKTableViewCellMapping cellMapping];
    ORKTableViewCellMapping *secondMapping = [ORKTableViewCellMapping cellMapping];
    [cellMappings setCellMapping:firstMapping forClass:[ORKTestSubclassedUser class]];
    [cellMappings setCellMapping:secondMapping forClass:[ORKTestUser class]];
    assertThat([cellMappings cellMappingForObject:[ORKTestUser new]], is(equalTo(secondMapping)));
}

- (void)testFindCellMappingsWithASubclassMatch
{
    ORKTableViewCellMappings *cellMappings = [ORKTableViewCellMappings cellMappings];
    ORKTableViewCellMapping *firstMapping = [ORKTableViewCellMapping cellMapping];
    ORKTableViewCellMapping *secondMapping = [ORKTableViewCellMapping cellMapping];
    [cellMappings setCellMapping:firstMapping forClass:[ORKTestUser class]];
    [cellMappings setCellMapping:secondMapping forClass:[ORKTestSubclassedUser class]];
    assertThat([cellMappings cellMappingForObject:[ORKTestSubclassedUser new]], is(equalTo(secondMapping)));
}

- (void)testReturnTheCellMappingForAnObjectInstance
{
    ORKTableViewCellMappings *cellMappings = [ORKTableViewCellMappings cellMappings];
    ORKTableViewCellMapping *mapping = [ORKTableViewCellMapping cellMapping];
    [cellMappings setCellMapping:mapping forClass:[ORKTestUser class]];
    assertThat([cellMappings cellMappingForObject:[ORKTestUser new]], is(equalTo(mapping)));
}

@end
