//
//  ORKObjectSerializerTest.m
//  RestKit
//
//  Created by Jeremy Ellison on 5/9/11.
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
#import "ORKObjectSerializer.h"
#import "ORKMappableObject.h"

@interface ORKObjectSerializerTest : ORKTestCase {
}

@end

@implementation ORKObjectSerializerTest

- (void)testShouldSerializeToFormEncodedData
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", @"value2", @"key2", nil];
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[NSDictionary class]];
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"key2" toKeyPath:@"key2-form-name"]];
    ORKObjectSerializer *serializer = [ORKObjectSerializer serializerWithObject:object mapping:mapping];
    NSError *error = nil;
    id<ORKRequestSerializable> serialization = [serializer serializationForMIMEType:@"application/x-www-form-urlencoded" error:&error];
    NSString *data = [[[NSString alloc] initWithData:[serialization HTTPBody] encoding:NSUTF8StringEncoding] autorelease];
    data = [data stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    assertThat(error, is(nilValue()));
    assertThat(data, is(equalTo(@"key2-form-name=value2&key1-form-name=value1")));
}

- (void)testShouldSerializeADateToFormEncodedData
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", [NSDate dateWithTimeIntervalSince1970:0], @"date", nil];
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[NSDictionary class]];
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"date" toKeyPath:@"date-form-name"]];
    ORKObjectSerializer *serializer = [ORKObjectSerializer serializerWithObject:object mapping:mapping];
    NSError *error = nil;
    id<ORKRequestSerializable> serialization = [serializer serializationForMIMEType:@"application/x-www-form-urlencoded" error:&error];

    NSString *data = [[[NSString alloc] initWithData:[serialization HTTPBody] encoding:NSUTF8StringEncoding] autorelease];
    data = [data stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    assertThat(error, is(nilValue()));
    assertThat(data, is(equalTo(@"key1-form-name=value1&date-form-name=1970-01-01 00:00:00 +0000")));
}

- (void)testShouldSerializeADateToAStringUsingThePreferredDateFormatter
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", [NSDate dateWithTimeIntervalSince1970:0], @"date", nil];
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[NSDictionary class]];
    NSDateFormatter *dateFormatter = [[NSDateFormatter new] autorelease];
    dateFormatter.dateFormat = @"MM/dd/yyyy";
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    mapping.preferredDateFormatter = dateFormatter;
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"date" toKeyPath:@"date-form-name"]];
    ORKObjectSerializer *serializer = [ORKObjectSerializer serializerWithObject:object mapping:mapping];
    NSError *error = nil;
    id<ORKRequestSerializable> serialization = [serializer serializationForMIMEType:@"application/x-www-form-urlencoded" error:&error];

    NSString *data = [[[NSString alloc] initWithData:[serialization HTTPBody] encoding:NSUTF8StringEncoding] autorelease];
    data = [data stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    assertThat(error, is(nilValue()));
    assertThat(data, is(equalTo(@"key1-form-name=value1&date-form-name=01/01/1970")));
}

- (void)testShouldSerializeADateToJSON
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", [NSDate dateWithTimeIntervalSince1970:0], @"date", nil];
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[NSDictionary class]];
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"date" toKeyPath:@"date-form-name"]];
    ORKObjectSerializer *serializer = [ORKObjectSerializer serializerWithObject:object mapping:mapping];

    NSError *error = nil;
    id<ORKRequestSerializable> serialization = [serializer serializationForMIMEType:@"application/json" error:&error];

    NSString *data = [[[NSString alloc] initWithData:[serialization HTTPBody] encoding:NSUTF8StringEncoding] autorelease];
    data = [data stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    assertThat(error, is(nilValue()));
    assertThat(data, is(equalTo(@"{\"key1-form-name\":\"value1\",\"date-form-name\":\"1970-01-01 00:00:00 +0000\"}")));
}

- (void)testShouldSerializeNSDecimalNumberAttributesToJSON
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", [NSDecimalNumber decimalNumberWithString:@"18274191731731.4557723623"], @"number", nil];
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[NSDictionary class]];
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"number" toKeyPath:@"number-form-name"]];
    ORKObjectSerializer *serializer = [ORKObjectSerializer serializerWithObject:object mapping:mapping];

    NSError *error = nil;
    id<ORKRequestSerializable> serialization = [serializer serializationForMIMEType:@"application/json" error:&error];

    NSString *data = [[[NSString alloc] initWithData:[serialization HTTPBody] encoding:NSUTF8StringEncoding] autorelease];
    data = [data stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    assertThat(error, is(nilValue()));
    assertThat(data, is(equalTo(@"{\"key1-form-name\":\"value1\",\"number-form-name\":\"18274191731731.4557723623\"}")));
}

- (void)testShouldSerializeRelationshipsToo
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", @"value2", @"key2",
                            [NSArray arrayWithObjects:
                             [NSDictionary dictionaryWithObjectsAndKeys:@"relationship1Value1", @"relatioship1Key1", nil],
                             [NSDictionary dictionaryWithObjectsAndKeys:@"relationship1Value2", @"relatioship1Key1", nil], nil], @"relationship1",
                            [NSDictionary dictionaryWithObjectsAndKeys:@"subValue1", @"subKey1", nil], @"relationship2",
                            nil];

    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"key2" toKeyPath:@"key2-form-name"]];
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"relationship1.relatioship1Key1" toKeyPath:@"relationship1-form-name[r1k1]"]];
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"relationship2.subKey1" toKeyPath:@"relationship2-form-name[subKey1]"]];

    ORKObjectSerializer *serializer = [ORKObjectSerializer serializerWithObject:object mapping:mapping];
    NSError *error = nil;
    id<ORKRequestSerializable> serialization = [serializer serializationForMIMEType:@"application/x-www-form-urlencoded" error:&error];
    NSString *data = [[[NSString alloc] initWithData:[serialization HTTPBody] encoding:NSUTF8StringEncoding] autorelease];
    data = [data stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    assertThat(error, is(nilValue()));
    #if TARGET_OS_IPHONE
    assertThat(data, is(equalTo(@"key1-form-name=value1&relationship1-form-name[r1k1][]=relationship1Value1&relationship1-form-name[r1k1][]=relationship1Value2&key2-form-name=value2&relationship2-form-name[subKey1]=subValue1")));
    #else
    assertThat(data, is(equalTo(@"relationship1-form-name[r1k1][]=relationship1Value1&relationship1-form-name[r1k1][]=relationship1Value2&key2-form-name=value2&key1-form-name=value1&relationship2-form-name[subKey1]=subValue1")));
    #endif
}

- (void)testShouldSerializeToJSON
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", @"value2", @"key2", nil];
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[NSDictionary class]];
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"key2" toKeyPath:@"key2-form-name"]];
    ORKObjectSerializer *serializer = [ORKObjectSerializer serializerWithObject:object mapping:mapping];
    NSError *error = nil;
    id<ORKRequestSerializable> serialization = [serializer serializationForMIMEType:@"application/json" error:&error];
    NSString *data = [[[NSString alloc] initWithData:[serialization HTTPBody] encoding:NSUTF8StringEncoding] autorelease];
    data = [data stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    assertThat(error, is(nilValue()));
    assertThat(data, is(equalTo(@"{\"key2-form-name\":\"value2\",\"key1-form-name\":\"value1\"}")));
}

- (void)testShouldSetReturnNilIfItDoesNotFindAnythingToSerialize
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", @"value2", @"key2", nil];
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[NSDictionary class]];
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"key12123" toKeyPath:@"key1-form-name"]];
    ORKObjectSerializer *serializer = [ORKObjectSerializer serializerWithObject:object mapping:mapping];
    NSError *error = nil;
    id<ORKRequestSerializable> serialization = [serializer serializationForMIMEType:@"application/json" error:&error];

    assertThat(serialization, is(nilValue()));
}

- (void)testShouldSerializeNestedObjectsContainingDatesToJSON
{
    ORKMappableObject *object = [[ORKMappableObject new] autorelease];
    object.stringTest = @"The string";
    ORKMappableAssociation *association = [[ORKMappableAssociation new] autorelease];
    association.date = [NSDate dateWithTimeIntervalSince1970:0];
    object.hasOne = association;

    // Setup object mappings
    ORKObjectMapping *objectMapping = [ORKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [objectMapping mapAttributes:@"stringTest", nil];
    ORKObjectMapping *relationshipMapping = [ORKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [relationshipMapping mapAttributes:@"date", nil];
    [objectMapping mapRelationship:@"hasOne" withMapping:relationshipMapping];

    // Serialize
    ORKObjectSerializer *serializer = [ORKObjectSerializer serializerWithObject:object mapping:objectMapping];
    NSError *error = nil;
    id<ORKRequestSerializable> serialization = [serializer serializationForMIMEType:@"application/json" error:&error];
    assertThat(error, is(nilValue()));

    NSString *data = [[[NSString alloc] initWithData:[serialization HTTPBody] encoding:NSUTF8StringEncoding] autorelease];
    data = [data stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    // Encodes differently on iOS / OS X
    #if TARGET_OS_IPHONE
    assertThat(data, is(equalTo(@"{\"stringTest\":\"The string\",\"hasOne\":{\"date\":\"1970-01-01 00:00:00 +0000\"}}")));
    #else
    assertThat(data, is(equalTo(@"{\"hasOne\":{\"date\":\"1970-01-01 00:00:00 +0000\"},\"stringTest\":\"The string\"}")));
    #endif
}

- (void)testShouldEncloseTheSerializationInAContainerIfRequested
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", @"value2", @"key2", nil];
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[NSDictionary class]];
    mapping.rootKeyPath = @"stuff";
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"key2" toKeyPath:@"key2-form-name"]];
    ORKObjectSerializer *serializer = [ORKObjectSerializer serializerWithObject:object mapping:mapping];
    NSError *error = nil;
    id<ORKRequestSerializable> serialization = [serializer serializationForMIMEType:@"application/x-www-form-urlencoded" error:&error];
    NSString *data = [[[NSString alloc] initWithData:[serialization HTTPBody] encoding:NSUTF8StringEncoding] autorelease];
    data = [data stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    assertThat(error, is(nilValue()));
    assertThat(data, is(equalTo(@"stuff[key2-form-name]=value2&stuff[key1-form-name]=value1")));
}

- (void)testShouldSerializeToManyRelationships
{
    ORKMappableObject *object = [[ORKMappableObject new] autorelease];
    object.stringTest = @"The string";
    ORKMappableAssociation *association = [[ORKMappableAssociation new] autorelease];
    association.date = [NSDate dateWithTimeIntervalSince1970:0];
    object.hasMany = [NSSet setWithObject:association];

    // Setup object mappings
    ORKObjectMapping *objectMapping = [ORKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [objectMapping mapAttributes:@"stringTest", nil];
    ORKObjectMapping *relationshipMapping = [ORKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [relationshipMapping mapAttributes:@"date", nil];
    [objectMapping mapRelationship:@"hasMany" withMapping:relationshipMapping];

    // Serialize
    ORKObjectSerializer *serializer = [ORKObjectSerializer serializerWithObject:object mapping:objectMapping];
    NSError *error = nil;
    id<ORKRequestSerializable> serialization = [serializer serializationForMIMEType:@"application/json" error:&error];
    assertThat(error, is(nilValue()));

    NSString *data = [[[NSString alloc] initWithData:[serialization HTTPBody] encoding:NSUTF8StringEncoding] autorelease];
    data = [data stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    assertThat(data, is(equalTo(@"{\"hasMany\":[{\"date\":\"1970-01-01 00:00:00 +0000\"}],\"stringTest\":\"The string\"}")));
}

- (void)testShouldSerializeAnNSNumberContainingABooleanToTrueFalseIfRequested
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", [NSNumber numberWithBool:YES], @"boolean", nil];
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[NSDictionary class]];
    ORKObjectAttributeMapping *attributeMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"boolean" toKeyPath:@"boolean-value"];
    [mapping addAttributeMapping:attributeMapping];
    ORKObjectSerializer *serializer = [ORKObjectSerializer serializerWithObject:object mapping:mapping];

    NSError *error = nil;
    id<ORKRequestSerializable> serialization = [serializer serializationForMIMEType:@"application/json" error:&error];

    NSString *data = [[[NSString alloc] initWithData:[serialization HTTPBody] encoding:NSUTF8StringEncoding] autorelease];
    data = [data stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    assertThat(error, is(nilValue()));
    assertThat(data, is(equalTo(@"{\"boolean-value\":true}")));
}

- (void)testShouldSerializeANSOrderedSetToJSON
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1",
                            [NSOrderedSet orderedSetWithObjects:@"setElementOne", @"setElementTwo", @"setElementThree", nil], @"set",
                            nil];
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[NSDictionary class]];
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"set" toKeyPath:@"set-form-name"]];
    ORKObjectSerializer *serializer = [ORKObjectSerializer serializerWithObject:object mapping:mapping];

    NSError *error = nil;
    id<ORKRequestSerializable> serialization = [serializer serializationForMIMEType:@"application/json" error:&error];

    NSString *data = [[[NSString alloc] initWithData:[serialization HTTPBody] encoding:NSUTF8StringEncoding] autorelease];
    data = [data stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    assertThat(error, is(nilValue()));
    assertThat(data, is(equalTo(@"{\"key1-form-name\":\"value1\",\"set-form-name\":[\"setElementOne\",\"setElementTwo\",\"setElementThree\"]}")));
}

@end
