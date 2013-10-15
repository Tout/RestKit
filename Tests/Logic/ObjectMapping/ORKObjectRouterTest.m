//
//  ORKObjectRouterTest.m
//  RestKit
//
//  Created by Blake Watters on 7/20/10.
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

#import "ORKTestEnvironment.h"
#import "NSManagedObject+ActiveRecord.h"
#import "ORKManagedObjectStore.h"
#import "ORKTestUser.h"

@interface ORKTestObject : NSObject
@end
@implementation ORKTestObject
+ (id)object
{
    return [[self new] autorelease];
}
@end

@interface ORKTestSubclassedObject : ORKTestObject
@end
@implementation ORKTestSubclassedObject
@end

@interface ORKObjectRouterTest : ORKTestCase {
}

@end

@implementation ORKTestUser (PolymorphicResourcePath)

- (NSString *)polymorphicResourcePath
{
    return @"/this/is/the/path";
}

@end

@implementation ORKObjectRouterTest

- (void)testThrowAnExceptionWhenAskedForAPathForAnUnregisteredClassAndMethod
{
    ORKObjectRouter *router = [[[ORKObjectRouter alloc] init] autorelease];
    NSException *exception = nil;
    @try {
        [router resourcePathForObject:[ORKTestObject object] method:ORKRequestMethodPOST];
    }
    @catch (NSException *e) {
        exception = e;
    }
    assertThat(exception, isNot(nilValue()));
}

- (void)testThrowAnExceptionWhenAskedForAPathForARegisteredClassButUnregisteredMethod
{
    ORKObjectRouter *router = [[[ORKObjectRouter alloc] init] autorelease];
    [router routeClass:[ORKTestObject class] toResourcePath:@"/HumanService.asp" forMethod:ORKRequestMethodGET];
    NSException *exception = nil;
    @try {
        [router resourcePathForObject:[ORKTestObject object] method:ORKRequestMethodPOST];
    }
    @catch (NSException *e) {
        exception = e;
    }
    assertThat(exception, isNot(nilValue()));
}

- (void)testReturnPathsRegisteredForTestificRequestMethods
{
    ORKObjectRouter *router = [[[ORKObjectRouter alloc] init] autorelease];
    [router routeClass:[ORKTestObject class] toResourcePath:@"/HumanService.asp" forMethod:ORKRequestMethodGET];
    NSString *path = [router resourcePathForObject:[ORKTestObject object] method:ORKRequestMethodGET];
    assertThat(path, is(equalTo(@"/HumanService.asp")));
}

- (void)testReturnPathsRegisteredForTheClassAsAWhole
{
    ORKObjectRouter *router = [[[ORKObjectRouter alloc] init] autorelease];
    [router routeClass:[ORKTestObject class] toResourcePath:@"/HumanService.asp"];
    NSString *path = [router resourcePathForObject:[ORKTestObject object] method:ORKRequestMethodGET];
    assertThat(path, is(equalTo(@"/HumanService.asp")));
    path = [router resourcePathForObject:[ORKTestObject object] method:ORKRequestMethodPOST];
    assertThat(path, is(equalTo(@"/HumanService.asp")));
}

- (void)testShouldReturnPathsIfTheSuperclassIsRegistered
{
    ORKObjectRouter *router = [[[ORKObjectRouter alloc] init] autorelease];
    [router routeClass:[ORKTestObject class] toResourcePath:@"/HumanService.asp"];
    NSString *path = [router resourcePathForObject:[ORKTestSubclassedObject new] method:ORKRequestMethodGET];
    assertThat(path, is(equalTo(@"/HumanService.asp")));
}

- (void)testShouldFavorExactMatcherOverSuperclassMatches
{
    ORKObjectRouter *router = [[[ORKObjectRouter alloc] init] autorelease];
    [router routeClass:[ORKTestObject class] toResourcePath:@"/HumanService.asp"];
    [router routeClass:[ORKTestSubclassedObject class] toResourcePath:@"/SubclassedHumanService.asp"];
    NSString *path = [router resourcePathForObject:[ORKTestSubclassedObject new] method:ORKRequestMethodGET];
    assertThat(path, is(equalTo(@"/SubclassedHumanService.asp")));
    path = [router resourcePathForObject:[ORKTestObject new] method:ORKRequestMethodPOST];
    assertThat(path, is(equalTo(@"/HumanService.asp")));
}

- (void)testFavorTestificMethodsWhenClassAndTestificMethodsAreRegistered
{
    ORKObjectRouter *router = [[[ORKObjectRouter alloc] init] autorelease];
    [router routeClass:[ORKTestObject class] toResourcePath:@"/HumanService.asp"];
    [router routeClass:[ORKTestObject class] toResourcePath:@"/HumanServiceForPUT.asp" forMethod:ORKRequestMethodPUT];
    NSString *path = [router resourcePathForObject:[ORKTestObject object] method:ORKRequestMethodGET];
    assertThat(path, is(equalTo(@"/HumanService.asp")));
    path = [router resourcePathForObject:[ORKTestObject object] method:ORKRequestMethodPOST];
    assertThat(path, is(equalTo(@"/HumanService.asp")));
    path = [router resourcePathForObject:[ORKTestObject object] method:ORKRequestMethodPUT];
    assertThat(path, is(equalTo(@"/HumanServiceForPUT.asp")));
}

- (void)testRaiseAnExceptionWhenAttemptIsMadeToRegisterOverAnExistingRoute
{
    ORKObjectRouter *router = [[[ORKObjectRouter alloc] init] autorelease];
    [router routeClass:[ORKTestObject class] toResourcePath:@"/HumanService.asp" forMethod:ORKRequestMethodGET];
    NSException *exception = nil;
    @try {
        [router routeClass:[ORKTestObject class] toResourcePathPattern:@"/HumanService.asp" forMethod:ORKRequestMethodGET];
    }
    @catch (NSException *e) {
        exception = e;
    }
    assertThat(exception, isNot(nilValue()));
}

- (void)testShouldInterpolatePropertyNamesReferencedInTheMapping
{
    ORKTestUser *blake = [ORKTestUser user];
    blake.name = @"blake";
    blake.userID = [NSNumber numberWithInt:31337];
    ORKObjectRouter *router = [[[ORKObjectRouter alloc] init] autorelease];
    [router routeClass:[ORKTestUser class] toResourcePathPattern:@"/humans/:userID/:name" forMethod:ORKRequestMethodGET];

    NSString *resourcePath = [router resourcePathForObject:blake method:ORKRequestMethodGET];
    assertThat(resourcePath, is(equalTo(@"/humans/31337/blake")));
}

- (void)testShouldInterpolatePropertyNamesReferencedInTheMappingWithDeprecatedParentheses
{
    ORKTestUser *blake = [ORKTestUser user];
    blake.name = @"blake";
    blake.userID = [NSNumber numberWithInt:31337];
    ORKObjectRouter *router = [[[ORKObjectRouter alloc] init] autorelease];
    [router routeClass:[ORKTestUser class] toResourcePathPattern:@"/humans/(userID)/(name)" forMethod:ORKRequestMethodGET];

    NSString *resourcePath = [router resourcePathForObject:blake method:ORKRequestMethodGET];
    assertThat(resourcePath, is(equalTo(@"/humans/31337/blake")));
}

- (void)testShouldAllowForPolymorphicURLsViaMethodCalls
{
    ORKTestUser *blake = [ORKTestUser user];
    blake.name = @"blake";
    blake.userID = [NSNumber numberWithInt:31337];
    ORKObjectRouter *router = [[[ORKObjectRouter alloc] init] autorelease];
    [router routeClass:[ORKTestUser class] toResourcePathPattern:@":polymorphicResourcePath" forMethod:ORKRequestMethodGET escapeRoutedPath:NO];

    NSString *resourcePath = [router resourcePathForObject:blake method:ORKRequestMethodGET];
    assertThat(resourcePath, is(equalTo(@"/this/is/the/path")));
}

- (void)testShouldAllowForPolymorphicURLsViaMethodCallsWithDeprecatedParentheses
{
    ORKTestUser *blake = [ORKTestUser user];
    blake.name = @"blake";
    blake.userID = [NSNumber numberWithInt:31337];
    ORKObjectRouter *router = [[[ORKObjectRouter alloc] init] autorelease];
    [router routeClass:[ORKTestUser class] toResourcePathPattern:@"(polymorphicResourcePath)" forMethod:ORKRequestMethodGET escapeRoutedPath:NO];

    NSString *resourcePath = [router resourcePathForObject:blake method:ORKRequestMethodGET];
    assertThat(resourcePath, is(equalTo(@"/this/is/the/path")));
}

@end
