//
//  ORKMutableBlockDictionaryTest.m
//  RestKit
//
//  Created by Blake Watters on 8/22/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "ORKTestEnvironment.h"
#import "ORKMutableBlockDictionary.h"

@interface ORKMutableBlockDictionaryTest : ORKTestCase

@end

@implementation ORKMutableBlockDictionaryTest

- (void)testLetYouAssignABlockToTheDictionary
{
    ORKMutableBlockDictionary *blockDictionary = [[ORKMutableBlockDictionary new] autorelease];
    [blockDictionary setValueWithBlock:^id{ return @"Value from the block!"; } forKey:@"theKey"];
    assertThat([blockDictionary valueForKey:@"theKey"], is(equalTo(@"Value from the block!")));
}

- (void)testLetYouUseKVC
{
    ORKMutableBlockDictionary *blockDictionary = [[ORKMutableBlockDictionary new] autorelease];
    [blockDictionary setValue:@"a value" forKey:@"a key"];
    assertThat([blockDictionary valueForKey:@"a key"], is(equalTo(@"a value")));
}

- (void)testLetYouAccessABlockValueUsingAKeyPath
{
    ORKMutableBlockDictionary *blockDictionary = [[ORKMutableBlockDictionary new] autorelease];
    [blockDictionary setValueWithBlock:^id{ return @"Value from the block!"; } forKey:@"theKey"];
    NSDictionary *otherDictionary = [NSDictionary dictionaryWithObject:blockDictionary forKey:@"dictionary"];
    assertThat([otherDictionary valueForKeyPath:@"dictionary.theKey"], is(equalTo(@"Value from the block!")));
}

@end
