//
//  ORKObjectMappingResultTest.m
//  RestKit
//
//  Created by Blake Watters on 7/5/11.
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
#import "ORKObjectMappingResult.h"

@interface ORKObjectMappingResultTest : ORKTestCase

@end

@implementation ORKObjectMappingResultTest

- (void)testShouldNotCrashWhenAsObjectIsInvokedOnAnEmptyResult
{
    NSException *exception = nil;
    ORKObjectMappingResult *result = [ORKObjectMappingResult mappingResultWithDictionary:[NSDictionary dictionary]];
    @try {
        [result asObject];
    }
    @catch (NSException *e) {
        exception = e;
    }
    @finally {
        assertThat(exception, is(nilValue()));
    }
}

- (void)testShouldReturnNilForAnEmptyCollectionCoercedToAsObject
{
    ORKObjectMappingResult *result = [ORKObjectMappingResult mappingResultWithDictionary:[NSDictionary dictionary]];
    assertThat([result asObject], is(equalTo(nil)));
}

- (void)testShouldReturnTheFirstObjectInTheCollectionWhenCoercedToAsObject
{
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"one", @"one", @"two", @"two", nil];
    ORKObjectMappingResult *result = [ORKObjectMappingResult mappingResultWithDictionary:dictionary];
    assertThat([result asObject], is(equalTo(@"one")));
}

@end
