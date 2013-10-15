//
//  ORKDynamicObjectMappingTest.m
//  RestKit
//
//  Created by Blake Watters on 7/28/11.
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
#import "ORKDynamicObjectMapping.h"
#import "ORKDynamicMappingModels.h"

@interface ORKDynamicObjectMappingTest : ORKTestCase <ORKDynamicObjectMappingDelegate>

@end

@implementation ORKDynamicObjectMappingTest

- (void)testShouldPickTheAppropriateMappingBasedOnAnAttributeValue
{
    ORKDynamicObjectMapping *dynamicMapping = [ORKDynamicObjectMapping dynamicMapping];
    ORKObjectMapping *girlMapping = [ORKObjectMapping mappingForClass:[Girl class] usingBlock:^(ORKObjectMapping *mapping) {
        [mapping mapAttributes:@"name", nil];
    }];
    ORKObjectMapping *boyMapping = [ORKObjectMapping mappingForClass:[Boy class] usingBlock:^(ORKObjectMapping *mapping) {
        [mapping mapAttributes:@"name", nil];
    }];
    [dynamicMapping setObjectMapping:girlMapping whenValueOfKeyPath:@"type" isEqualTo:@"Girl"];
    [dynamicMapping setObjectMapping:boyMapping whenValueOfKeyPath:@"type" isEqualTo:@"Boy"];
    ORKObjectMapping *mapping = [dynamicMapping objectMappingForDictionary:[ORKTestFixture parsedObjectWithContentsOfFixture:@"girl.json"]];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Girl")));
    mapping = [dynamicMapping objectMappingForDictionary:[ORKTestFixture parsedObjectWithContentsOfFixture:@"boy.json"]];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Boy")));
}

- (void)testShouldMatchOnAnNSNumberAttributeValue
{
    ORKDynamicObjectMapping *dynamicMapping = [ORKDynamicObjectMapping dynamicMapping];
    ORKObjectMapping *girlMapping = [ORKObjectMapping mappingForClass:[Girl class] usingBlock:^(ORKObjectMapping *mapping) {
        [mapping mapAttributes:@"name", nil];
    }];
    ORKObjectMapping *boyMapping = [ORKObjectMapping mappingForClass:[Boy class] usingBlock:^(ORKObjectMapping *mapping) {
        [mapping mapAttributes:@"name", nil];
    }];
    [dynamicMapping setObjectMapping:girlMapping whenValueOfKeyPath:@"numeric_type" isEqualTo:[NSNumber numberWithInt:0]];
    [dynamicMapping setObjectMapping:boyMapping whenValueOfKeyPath:@"numeric_type" isEqualTo:[NSNumber numberWithInt:1]];
    ORKObjectMapping *mapping = [dynamicMapping objectMappingForDictionary:[ORKTestFixture parsedObjectWithContentsOfFixture:@"girl.json"]];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Girl")));
    mapping = [dynamicMapping objectMappingForDictionary:[ORKTestFixture parsedObjectWithContentsOfFixture:@"boy.json"]];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Boy")));
}

- (void)testShouldPickTheAppropriateMappingBasedOnDelegateCallback
{
    ORKDynamicObjectMapping *dynamicMapping = [ORKDynamicObjectMapping dynamicMapping];
    dynamicMapping.delegate = self;
    ORKObjectMapping *mapping = [dynamicMapping objectMappingForDictionary:[ORKTestFixture parsedObjectWithContentsOfFixture:@"girl.json"]];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Girl")));
    mapping = [dynamicMapping objectMappingForDictionary:[ORKTestFixture parsedObjectWithContentsOfFixture:@"boy.json"]];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Boy")));
}

- (void)testShouldPickTheAppropriateMappingBasedOnBlockDelegateCallback
{
    ORKDynamicObjectMapping *dynamicMapping = [ORKDynamicObjectMapping dynamicMapping];
    dynamicMapping.objectMappingForDataBlock = ^ ORKObjectMapping *(id data) {
        if ([[data valueForKey:@"type"] isEqualToString:@"Girl"]) {
            return [ORKObjectMapping mappingForClass:[Girl class] usingBlock:^(ORKObjectMapping *mapping) {
                [mapping mapAttributes:@"name", nil];
            }];
        } else if ([[data valueForKey:@"type"] isEqualToString:@"Boy"]) {
            return [ORKObjectMapping mappingForClass:[Boy class] usingBlock:^(ORKObjectMapping *mapping) {
                [mapping mapAttributes:@"name", nil];
            }];
        }

        return nil;
    };
    ORKObjectMapping *mapping = [dynamicMapping objectMappingForDictionary:[ORKTestFixture parsedObjectWithContentsOfFixture:@"girl.json"]];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Girl")));
    mapping = [dynamicMapping objectMappingForDictionary:[ORKTestFixture parsedObjectWithContentsOfFixture:@"boy.json"]];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Boy")));
}

- (void)testShouldFailAnAssertionWhenInvokedWithSomethingOtherThanADictionary
{
    NSException *exception = nil;
    ORKDynamicObjectMapping *dynamicMapping = [ORKDynamicObjectMapping dynamicMapping];
    @try {
        [dynamicMapping objectMappingForDictionary:(NSDictionary *)[NSArray array]];
    }
    @catch (NSException *e) {
        exception = e;
    }
    @finally {
        assertThat(exception, is(notNilValue()));
    }
}

#pragma mark - ORKDynamicObjectMappingDelegate

- (ORKObjectMapping *)objectMappingForData:(id)data
{
    if ([[data valueForKey:@"type"] isEqualToString:@"Girl"]) {
        return [ORKObjectMapping mappingForClass:[Girl class] usingBlock:^(ORKObjectMapping *mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    } else if ([[data valueForKey:@"type"] isEqualToString:@"Boy"]) {
        return [ORKObjectMapping mappingForClass:[Boy class] usingBlock:^(ORKObjectMapping *mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }

    return nil;
}

@end
