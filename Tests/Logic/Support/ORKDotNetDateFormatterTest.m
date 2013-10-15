//
//  ORKDotNetDateFormatterTest.m
//  RestKit
//
//  Created by Greg Combs on 9/8/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "ORKTestEnvironment.h"
#import "ORKDotNetDateFormatter.h"

@interface ORKDotNetDateFormatterTest : ORKTestCase

@end

@implementation ORKDotNetDateFormatterTest

- (void)testShouldInstantiateAFormatterWithDefaultGMTTimeZone
{
    ORKDotNetDateFormatter *formatter = [ORKDotNetDateFormatter dotNetDateFormatter];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    assertThat(formatter, isNot(equalTo(nil)));
    assertThat(formatter.timeZone, is(equalTo(timeZone)));
}


- (void)testShouldInstantiateAFormatterWithATimeZone
{
    NSTimeZone *timeZoneCST = [NSTimeZone timeZoneWithAbbreviation:@"CST"];
    ORKDotNetDateFormatter *formatter = [ORKDotNetDateFormatter dotNetDateFormatterWithTimeZone:timeZoneCST];
    assertThat(formatter, isNot(equalTo(nil)));
    assertThat(formatter.timeZone, is(equalTo(timeZoneCST)));
}

- (void)testShouldCreateADateFromDotNetThatWithAnOffset
{
    NSString *dotNetString = @"/Date(1000212360000-0400)/";
    ORKDotNetDateFormatter *formatter = [ORKDotNetDateFormatter dotNetDateFormatter];
    NSDate *date = [formatter dateFromString:dotNetString];
    assertThat([date description], is(equalTo(@"2001-09-11 12:46:00 +0000")));
}

- (void)testShouldCreateADateFromDotNetWithoutAnOffset
{
    NSString *dotNetString = @"/Date(1112715000000)/";
    ORKDotNetDateFormatter *formatter = [ORKDotNetDateFormatter dotNetDateFormatter];
    NSDate *date = [formatter dateFromString:dotNetString];
    assertThat([date description], is(equalTo(@"2005-04-05 15:30:00 +0000")));
}

- (void)testShouldCreateADateFromDotNetBefore1970WithoutAnOffset
{
    NSString *dotNetString = @"/Date(-864000000000)/";
    ORKDotNetDateFormatter *formatter = [ORKDotNetDateFormatter dotNetDateFormatter];
    NSDate *date = [formatter dateFromString:dotNetString];
    assertThat([date description], is(equalTo(@"1942-08-16 00:00:00 +0000")));
}

- (void)testShouldFailToCreateADateFromInvalidStrings
{
    ORKDotNetDateFormatter *formatter = [ORKDotNetDateFormatter dotNetDateFormatter];
    NSDate *date = [formatter dateFromString:nil];
    assertThat(date, is(equalTo(nil)));
    date = [formatter dateFromString:@"(null)"];
    assertThat(date, is(equalTo(nil)));
    date = [formatter dateFromString:@"1112715000-0500"];
    assertThat(date, is(equalTo(nil)));
}

- (void)testShouldCreateADotNetStringFromADateWithATimeZone
{
    NSTimeZone *timeZoneEST = [NSTimeZone timeZoneWithAbbreviation:@"EST"];
    ORKDotNetDateFormatter *formatter = [ORKDotNetDateFormatter dotNetDateFormatterWithTimeZone:timeZoneEST];
    NSDate *referenceDate = [NSDate dateWithTimeIntervalSince1970:1000212360];
    NSString *string = [formatter stringFromDate:referenceDate];
    assertThat(formatter.timeZone, is(equalTo(timeZoneEST)));
    assertThat(string, is(equalTo(@"/Date(1000212360000-0400)/")));
}

- (void)testShouldCreateADotNetStringFromADateBefore1970WithoutAnOffset
{
    ORKDotNetDateFormatter *formatter = [ORKDotNetDateFormatter dotNetDateFormatter];
    NSDate *referenceDate = [NSDate dateWithTimeIntervalSince1970:-1000212360];
    NSString *string = [formatter stringFromDate:referenceDate];
    assertThat(string, is(equalTo(@"/Date(-1000212360000+0000)/")));
}

- (void)testShouldCreateADateWithGetObjectValueForString
{
    ORKDotNetDateFormatter *formatter = [ORKDotNetDateFormatter dotNetDateFormatter];
    NSString *dotNetString = @"/Date(1000212360000-0400)/";

    NSDate *date = nil;
    NSString *errorDescription = nil;
    BOOL success = [formatter getObjectValue:&date forString:dotNetString errorDescription:&errorDescription];

    assertThatBool(success, is(equalToBool(YES)));
    assertThat([date description], is(equalTo(@"2001-09-11 12:46:00 +0000")));
}

@end
