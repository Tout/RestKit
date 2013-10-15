//
//  ORKTestEnvironment.m
//  RestKit
//
//  Created by Blake Watters on 3/14/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#include <objc/runtime.h>
#import "ORKTestEnvironment.h"
#import "ORKParserRegistry.h"

ORKOAuthClient *ORKTestNewOAuthClient(ORKTestResponseLoader *loader)
{
    [loader setTimeout:10];
    ORKOAuthClient *client = [ORKOAuthClient clientWithClientID:@"4fa42a4a7184796662000001" secret:@"restkit_secret"];
    client.delegate = loader;
    client.authorizationURL = [NSString stringWithFormat:@"%@/oauth2/pregen/token", [ORKTestFactory baseURLString]];
    return client;
}

@implementation ORKTestCase

+ (void)initialize
{
    // Configure fixture bundle. The 'org.restkit.tests' identifier is shared between
    // the logic and application test bundles
    NSBundle *fixtureBundle = [NSBundle bundleWithIdentifier:@"org.restkit.tests"];
    [ORKTestFixture setFixtureBundle:fixtureBundle];

    // Ensure the required directories exist
    BOOL directoryExists;
    NSError *error = nil;
    directoryExists = [ORKDirectory ensureDirectoryExistsAtPath:[ORKDirectory applicationDataDirectory] error:&error];
    if (! directoryExists) {
        ORKLogError(@"Failed to create application data directory. Unable to run tests: %@", error);
        NSAssert(directoryExists, @"Failed to create application data directory.");
    }

    directoryExists = [ORKDirectory ensureDirectoryExistsAtPath:[ORKDirectory cachesDirectory] error:&error];
    if (! directoryExists) {
        ORKLogError(@"Failed to create caches directory. Unable to run tests: %@", error);
        NSAssert(directoryExists, @"Failed to create caches directory.");
    }
}

@end

@implementation SenTestCase (MethodSwizzling)

- (void)swizzleMethod:(SEL)aOriginalMethod
              inClass:(Class)aOriginalClass
           withMethod:(SEL)aNewMethod
            fromClass:(Class)aNewClass
         executeBlock:(void (^)(void))aBlock
{
    Method originalMethod = class_getClassMethod(aOriginalClass, aOriginalMethod);
    Method mockMethod = class_getInstanceMethod(aNewClass, aNewMethod);
    method_exchangeImplementations(originalMethod, mockMethod);
    aBlock();
    method_exchangeImplementations(mockMethod, originalMethod);
}

@end
