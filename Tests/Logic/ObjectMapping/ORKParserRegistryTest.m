//
//  ORKParserRegistryTest.m
//  RestKit
//
//  Created by Blake Watters on 5/18/11.
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
#import "ORKParserRegistry.h"
#import "ORKJSONParserJSONKit.h"
#import "ORKXMLParserXMLReader.h"

@interface ORKParserRegistryTest : ORKTestCase {
}

@end

@implementation ORKParserRegistryTest

- (void)testShouldEnableRegistrationFromMIMETypeToParserClasses
{
    ORKParserRegistry *registry = [[ORKParserRegistry new] autorelease];
    [registry setParserClass:[ORKJSONParserJSONKit class] forMIMEType:ORKMIMETypeJSON];
    Class parserClass = [registry parserClassForMIMEType:ORKMIMETypeJSON];
    assertThat(NSStringFromClass(parserClass), is(equalTo(@"ORKJSONParserJSONKit")));
}

- (void)testShouldInstantiateParserObjects
{
    ORKParserRegistry *registry = [[ORKParserRegistry new] autorelease];
    [registry setParserClass:[ORKJSONParserJSONKit class] forMIMEType:ORKMIMETypeJSON];
    id<ORKParser> parser = [registry parserForMIMEType:ORKMIMETypeJSON];
    assertThat(parser, is(instanceOf([ORKJSONParserJSONKit class])));
}

- (void)testShouldAutoconfigureBasedOnReflection
{
    ORKParserRegistry *registry = [[ORKParserRegistry new] autorelease];
    [registry autoconfigure];
    id<ORKParser> parser = [registry parserForMIMEType:ORKMIMETypeJSON];
    assertThat(parser, is(instanceOf([ORKJSONParserJSONKit class])));
    parser = [registry parserForMIMEType:ORKMIMETypeXML];
    assertThat(parser, is(instanceOf([ORKXMLParserXMLReader class])));
}

- (void)testRetrievalOfExactStringMatchForMIMEType
{
    ORKParserRegistry *registry = [[ORKParserRegistry new] autorelease];
    [registry setParserClass:[ORKJSONParserJSONKit class] forMIMEType:ORKMIMETypeJSON];
    id<ORKParser> parser = [registry parserForMIMEType:ORKMIMETypeJSON];
    assertThat(parser, is(instanceOf([ORKJSONParserJSONKit class])));
}

- (void)testRetrievalOfRegularExpressionMatchForMIMEType
{
    ORKParserRegistry *registry = [[ORKParserRegistry new] autorelease];
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"application/xml\\+\\w+" options:0 error:&error];
    [registry setParserClass:[ORKJSONParserJSONKit class] forMIMETypeRegularExpression:regex];
    id<ORKParser> parser = [registry parserForMIMEType:@"application/xml+whatever"];
    assertThat(parser, is(instanceOf([ORKJSONParserJSONKit class])));
}

- (void)testRetrievalOfExactStringMatchIsFavoredOverRegularExpression
{
    ORKParserRegistry *registry = [[ORKParserRegistry new] autorelease];
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"application/xml\\+\\w+" options:0 error:&error];
    [registry setParserClass:[ORKJSONParserJSONKit class] forMIMETypeRegularExpression:regex];
    [registry setParserClass:[ORKXMLParserXMLReader class] forMIMEType:@"application/xml+whatever"];

    // Exact match
    id<ORKParser> exactParser = [registry parserForMIMEType:@"application/xml+whatever"];
    assertThat(exactParser, is(instanceOf([ORKXMLParserXMLReader class])));

    // Fallback to regex
    id<ORKParser> regexParser = [registry parserForMIMEType:@"application/xml+different"];
    assertThat(regexParser, is(instanceOf([ORKJSONParserJSONKit class])));
}

@end
