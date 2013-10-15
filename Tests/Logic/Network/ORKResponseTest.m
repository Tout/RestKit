//
//  ORKResponseTest.m
//  RestKit
//
//  Created by Blake Watters on 1/15/10.
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
#import "ORKResponse.h"

@interface ORKResponseTest : ORKTestCase {
    ORKResponse *_response;
}

@end

@implementation ORKResponseTest

- (void)setUp
{
    _response = [[ORKResponse alloc] init];
}

- (void)testShouldConsiderResponsesLessThanOneHudredOrGreaterThanSixHundredInvalid
{
    ORKResponse *response = [[[ORKResponse alloc] init] autorelease];
    id mock = [OCMockObject partialMockForObject:response];
    NSInteger statusCode = 99;
    [[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
    assertThatBool([mock isInvalid], is(equalToBool(YES)));
    statusCode = 601;
    [[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
    assertThatBool([mock isInvalid], is(equalToBool(YES)));
}

- (void)testShouldConsiderResponsesInTheOneHudredsInformational
{
    ORKResponse *response = [[[ORKResponse alloc] init] autorelease];
    id mock = [OCMockObject partialMockForObject:response];
    NSInteger statusCode = 100;
    [[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
    assertThatBool([mock isInformational], is(equalToBool(YES)));
    statusCode = 199;
    [[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
    assertThatBool([mock isInformational], is(equalToBool(YES)));
}

- (void)testShouldConsiderResponsesInTheTwoHundredsSuccessful
{
    ORKResponse *response = [[[ORKResponse alloc] init] autorelease];
    id mock = [OCMockObject partialMockForObject:response];
    NSInteger twoHundred = 200;
    [[[mock stub] andReturnValue:OCMOCK_VALUE(twoHundred)] statusCode];
    assertThatBool([mock isSuccessful], is(equalToBool(YES)));
    twoHundred = 299;
    [[[mock stub] andReturnValue:OCMOCK_VALUE(twoHundred)] statusCode];
    assertThatBool([mock isSuccessful], is(equalToBool(YES)));
}

- (void)testShouldConsiderResponsesInTheThreeHundredsRedirects
{
    ORKResponse *response = [[[ORKResponse alloc] init] autorelease];
    id mock = [OCMockObject partialMockForObject:response];
    NSInteger statusCode = 300;
    [[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
    assertThatBool([mock isRedirection], is(equalToBool(YES)));
    statusCode = 399;
    [[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
    assertThatBool([mock isRedirection], is(equalToBool(YES)));
}

- (void)testShouldConsiderResponsesInTheFourHundredsClientErrors
{
    ORKResponse *response = [[[ORKResponse alloc] init] autorelease];
    id mock = [OCMockObject partialMockForObject:response];
    NSInteger statusCode = 400;
    [[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
    assertThatBool([mock isClientError], is(equalToBool(YES)));
    statusCode = 499;
    [[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
    assertThatBool([mock isClientError], is(equalToBool(YES)));
}

- (void)testShouldConsiderResponsesInTheFiveHundredsServerErrors
{
    ORKResponse *response = [[[ORKResponse alloc] init] autorelease];
    id mock = [OCMockObject partialMockForObject:response];
    NSInteger statusCode = 500;
    [[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
    assertThatBool([mock isServerError], is(equalToBool(YES)));
    statusCode = 599;
    [[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
    assertThatBool([mock isServerError], is(equalToBool(YES)));
}

- (void)testShouldConsiderATwoHundredResponseOK
{
    ORKResponse *response = [[[ORKResponse alloc] init] autorelease];
    id mock = [OCMockObject partialMockForObject:response];
    NSInteger statusCode = 200;
    [[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
    assertThatBool([mock isOK], is(equalToBool(YES)));
}

- (void)testShouldConsiderATwoHundredAndOneResponseCreated
{
    ORKResponse *response = [[[ORKResponse alloc] init] autorelease];
    id mock = [OCMockObject partialMockForObject:response];
    NSInteger statusCode = 201;
    [[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
    assertThatBool([mock isCreated], is(equalToBool(YES)));
}

- (void)testShouldConsiderAFourOhThreeResponseForbidden
{
    ORKResponse *response = [[[ORKResponse alloc] init] autorelease];
    id mock = [OCMockObject partialMockForObject:response];
    NSInteger statusCode = 403;
    [[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
    assertThatBool([mock isForbidden], is(equalToBool(YES)));
}

- (void)testShouldConsiderAFourOhFourResponseNotFound
{
    ORKResponse *response = [[[ORKResponse alloc] init] autorelease];
    id mock = [OCMockObject partialMockForObject:response];
    NSInteger statusCode = 404;
    [[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
    assertThatBool([mock isNotFound], is(equalToBool(YES)));
}

- (void)testShouldConsiderAFourOhNineResponseConflict
{
    ORKResponse *response = [[[ORKResponse alloc] init] autorelease];
    id mock = [OCMockObject partialMockForObject:response];
    NSInteger statusCode = 409;
    [[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
    assertThatBool([mock isConflict], is(equalToBool(YES)));
}

- (void)testShouldConsiderAFourHundredAndTenResponseConflict
{
    ORKResponse *response = [[[ORKResponse alloc] init] autorelease];
    id mock = [OCMockObject partialMockForObject:response];
    NSInteger statusCode = 410;
    [[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
    assertThatBool([mock isGone], is(equalToBool(YES)));
}

- (void)testShouldConsiderVariousThreeHundredResponsesRedirect
{
    ORKResponse *response = [[[ORKResponse alloc] init] autorelease];
    id mock = [OCMockObject partialMockForObject:response];
    NSInteger statusCode = 301;
    [[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
    assertThatBool([mock isRedirect], is(equalToBool(YES)));
    statusCode = 302;
    [[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
    assertThatBool([mock isRedirect], is(equalToBool(YES)));
    statusCode = 303;
    [[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
    assertThatBool([mock isRedirect], is(equalToBool(YES)));
    statusCode = 307;
    [[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
    assertThatBool([mock isRedirect], is(equalToBool(YES)));
}

- (void)testShouldConsiderVariousResponsesEmpty
{
    ORKResponse *response = [[[ORKResponse alloc] init] autorelease];
    id mock = [OCMockObject partialMockForObject:response];
    NSInteger statusCode = 201;
    [[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
    assertThatBool([mock isEmpty], is(equalToBool(YES)));
    statusCode = 204;
    [[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
    assertThatBool([mock isEmpty], is(equalToBool(YES)));
    statusCode = 304;
    [[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
    assertThatBool([mock isEmpty], is(equalToBool(YES)));
}

- (void)testShouldMakeTheContentTypeHeaderAccessible
{
    ORKResponse *response = [[[ORKResponse alloc] init] autorelease];
    id mock = [OCMockObject partialMockForObject:response];
    NSDictionary *headers = [NSDictionary dictionaryWithObject:@"application/xml" forKey:@"Content-Type"];
    [[[mock stub] andReturn:headers] allHeaderFields];
    assertThat([mock contentType], is(equalTo(@"application/xml")));
}

// Should this return a string???
- (void)testShouldMakeTheContentLengthHeaderAccessible
{
    ORKResponse *response = [[[ORKResponse alloc] init] autorelease];
    id mock = [OCMockObject partialMockForObject:response];
    NSDictionary *headers = [NSDictionary dictionaryWithObject:@"12345" forKey:@"Content-Length"];
    [[[mock stub] andReturn:headers] allHeaderFields];
    assertThat([mock contentLength], is(equalTo(@"12345")));
}

- (void)testShouldMakeTheLocationHeaderAccessible
{
    ORKResponse *response = [[[ORKResponse alloc] init] autorelease];
    id mock = [OCMockObject partialMockForObject:response];
    NSDictionary *headers = [NSDictionary dictionaryWithObject:@"/foo/bar" forKey:@"Location"];
    [[[mock stub] andReturn:headers] allHeaderFields];
    assertThat([mock location], is(equalTo(@"/foo/bar")));
}

- (void)testShouldKnowIfItIsAnXMLResponse
{
    ORKResponse *response = [[[ORKResponse alloc] init] autorelease];
    id mock = [OCMockObject partialMockForObject:response];
    NSDictionary *headers = [NSDictionary dictionaryWithObject:@"application/xml" forKey:@"Content-Type"];
    [[[mock stub] andReturn:headers] allHeaderFields];
    assertThatBool([mock isXML], is(equalToBool(YES)));
}

- (void)testShouldKnowIfItIsAnJSONResponse
{
    ORKResponse *response = [[[ORKResponse alloc] init] autorelease];
    id mock = [OCMockObject partialMockForObject:response];
    NSDictionary *headers = [NSDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"];
    [[[mock stub] andReturn:headers] allHeaderFields];
    assertThatBool([mock isJSON], is(equalToBool(YES)));
}

- (void)testShouldReturnParseErrorsWhenParsedBodyFails
{
    ORKResponse *response = [[[ORKResponse alloc] init] autorelease];
    id mock = [OCMockObject partialMockForObject:response];
    [[[mock stub] andReturn:@"sad;sdvjnk;"] bodyAsString];
    [[[mock stub] andReturn:@"application/json"] MIMEType];
    NSError *error = nil;
    id object = [mock parsedBody:&error];
    assertThat(object, is(nilValue()));
    assertThat(error, isNot(nilValue()));
    assertThat([error localizedDescription], is(equalTo(@"Unexpected token, wanted '{', '}', '[', ']', ',', ':', 'true', 'false', 'null', '\"STRING\"', 'NUMBER'.")));
}

- (void)testShouldNotCrashOnFailureToParseBody
{
    ORKResponse *response = [[ORKResponse new] autorelease];
    id mockResponse = [OCMockObject partialMockForObject:response];
    [[[mockResponse stub] andReturn:@"test/fake"] MIMEType];
    [[[mockResponse stub] andReturn:@"whatever"] bodyAsString];
    NSError *error = nil;
    id parsedResponse = [mockResponse parsedBody:&error];
    assertThat(parsedResponse, is(nilValue()));
}

- (void)testShouldNotCrashWhenParserReturnsNilWithoutAnError
{
    ORKResponse *response = [[[ORKResponse alloc] init] autorelease];
    id mockResponse = [OCMockObject partialMockForObject:response];
    [[[mockResponse stub] andReturn:@""] bodyAsString];
    [[[mockResponse stub] andReturn:ORKMIMETypeJSON] MIMEType];
    id mockParser = [OCMockObject mockForProtocol:@protocol(ORKParser)];
    id mockRegistry = [OCMockObject partialMockForObject:[ORKParserRegistry sharedRegistry]];
    [[[mockRegistry expect] andReturn:mockParser] parserForMIMEType:ORKMIMETypeJSON];
    NSError *error = nil;
    [[[mockParser expect] andReturn:nil] objectFromString:@"" error:[OCMArg setTo:error]];
    id object = [mockResponse parsedBody:&error];
    [mockRegistry verify];
    [mockParser verify];
    [ORKParserRegistry setSharedRegistry:nil];
    assertThat(object, is(nilValue()));
    assertThat(error, is(nilValue()));
}

- (void)testLoadingNonUTF8Charset
{
    ORKClient *client = [ORKTestFactory client];
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    [client get:@"/encoding" delegate:loader];
    [loader waitForResponse];
    assertThat([loader.response bodyEncodingName], is(equalTo(@"us-ascii")));
    assertThatInteger([loader.response bodyEncoding], is(equalToInteger(NSASCIIStringEncoding)));
}

- (void)testFollowRedirect
{
    ORKClient *client = [ORKTestFactory client];
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    [client get:@"/redirection" delegate:loader];
    [loader waitForResponse];
    assertThatInteger(loader.response.statusCode, is(equalToInteger(200)));

    id body = [loader.response parsedBody:NULL];
    assertThat([body objectForKey:@"redirected"], is(equalTo([NSNumber numberWithBool:YES])));
}

- (void)testNoFollowRedirect
{
    ORKClient *client = [ORKTestFactory client];
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];

    ORKRequest *request = [client requestWithResourcePath:@"/redirection"];
    request.method = ORKRequestMethodGET;
    request.followRedirect = NO;
    request.delegate = loader;

    [request send];
    [loader waitForResponse];

    assertThatInteger(loader.response.statusCode, is(equalToInteger(302)));
    assertThat([loader.response.allHeaderFields objectForKey:@"Location"], is(equalTo(@"/redirection/target")));
}

- (void)testThatLoadingInvalidURLDoesNotCrashApp
{
    NSURL *URL = [[NSURL alloc] initWithString:@"http://localhost:5629"];
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    ORKClient *client = [ORKClient clientWithBaseURL:URL];

    ORKRequest *request = [client requestWithResourcePath:@"/invalid"];
    request.method = ORKRequestMethodGET;
    request.delegate = loader;

    [request sendAsynchronously];
    [loader waitForResponse];
}

@end
