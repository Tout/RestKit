//
//  ORKCacheTest.m
//  RestKit
//
//  Created by Blake Watters on 4/17/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "ORKTestEnvironment.h"
#import "ORKDirectory.h"

@interface ORKCacheTest : ORKTestCase

@end

@implementation ORKCacheTest

- (void)testCreationOfIntermediateDirectories
{
    NSString *cachePath = [ORKDirectory cachesDirectory];
    NSString *subPath = [cachePath stringByAppendingPathComponent:@"TestPath"];
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:cachePath error:&error];

    [[ORKCache alloc] initWithPath:subPath subDirectories:nil];
    BOOL isDirectory;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:subPath isDirectory:&isDirectory];
    assertThatBool(fileExists, is(equalToBool(YES)));
    assertThatBool(isDirectory, is(equalToBool(YES)));
}

@end
