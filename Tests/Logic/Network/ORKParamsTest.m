//
//  ORKParamsTest.m
//  RestKit
//
//  Created by Blake Watters on 6/30/11.
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
#import "ORKParams.h"
#import "ORKRequest.h"

@interface ORKParamsTest : ORKTestCase

@end

@implementation ORKParamsTest

- (void)testShouldNotOverReleaseTheParams
{
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:@"foo" forKey:@"bar"];
    ORKParams *params = [[ORKParams alloc] initWithDictionary:dictionary];
    NSURL *URL = [NSURL URLWithString:[[ORKTestFactory baseURLString] stringByAppendingFormat:@"/echo_params"]];
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
    request.method = ORKRequestMethodPOST;
    request.params = params;
    request.delegate = responseLoader;
    [request sendAsynchronously];
    [responseLoader waitForResponse];
    [request release];
}

- (void)testShouldUploadFilesViaORKParams
{
    ORKClient *client = [ORKTestFactory client];
    ORKParams *params = [ORKParams params];
    [params setValue:@"one" forParam:@"value"];
    [params setValue:@"two" forParam:@"value"];
    [params setValue:@"three" forParam:@"value"];
    [params setValue:@"four" forParam:@"value"];
    NSData *data = [ORKTestFixture dataWithContentsOfFixture:@"blake.png"];
    [params setData:data MIMEType:@"image/png" forParam:@"file"];
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    [client post:@"/upload" params:params delegate:responseLoader];
    [responseLoader waitForResponse];
    assertThatInteger(responseLoader.response.statusCode, is(equalToInt(200)));
}

- (void)testShouldUploadFilesViaORKParamsWithMixedTypes
{
    NSNumber *idUsuari = [NSNumber numberWithInt:1234];
    NSArray *userList = [NSArray arrayWithObjects:@"one", @"two", @"three", nil];
    NSNumber *idTema = [NSNumber numberWithInt:1234];
    NSString *titulo = @"whatever";
    NSString *texto = @"more text";
    NSData *data = [ORKTestFixture dataWithContentsOfFixture:@"blake.png"];
    NSNumber *cel = [NSNumber numberWithFloat:1.232442];
    NSNumber *lon = [NSNumber numberWithFloat:18231.232442];;
    NSNumber *lat = [NSNumber numberWithFloat:13213123.232442];;

    ORKParams *params = [ORKParams params];

    // Set values
    [params setValue:idUsuari forParam:@"idUsuariPropietari"];
    [params setValue:userList forParam:@"telUser"];
    [params setValue:idTema forParam:@"idTema"];
    [params setValue:titulo forParam:@"titulo"];
    [params setValue:texto forParam:@"texto"];

    [params setData:data MIMEType:@"image/png" forParam:@"file"];

    [params setValue:cel forParam:@"cel"];
    [params setValue:lon forParam:@"lon"];
    [params setValue:lat forParam:@"lat"];

    ORKClient *client = [ORKTestFactory client];
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    [client post:@"/upload" params:params delegate:responseLoader];
    [responseLoader waitForResponse];
    assertThatInteger(responseLoader.response.statusCode, is(equalToInt(200)));
}

- (void)testShouldCalculateAnMD5ForTheParams
{
    NSDictionary *values = [NSDictionary dictionaryWithObjectsAndKeys:@"foo", @"bar", @"this", @"that", nil];
    ORKParams *params = [ORKParams paramsWithDictionary:values];
    NSString *MD5 = [params MD5];
    assertThat(MD5, is(equalTo(@"da7d80084b86aa5022b434e3bf084caf")));
}

- (void)testShouldProperlyCalculateContentLengthForFileUploads
{
    ORKClient *client = [ORKTestFactory client];
    ORKParams *params = [ORKParams params];
    [params setValue:@"one" forParam:@"value"];
    [params setValue:@"two" forParam:@"value"];
    [params setValue:@"three" forParam:@"value"];
    [params setValue:@"four" forParam:@"value"];
    NSData *data = [ORKTestFixture dataWithContentsOfFixture:@"blake.png"];
    [params setData:data MIMEType:@"image/png" forParam:@"file"];
    ORKRequest *request = [client requestWithResourcePath:@"/upload"];
    [request setMethod:ORKRequestMethodPOST];
    request.params = params;
    [request prepareURLRequest];
    assertThatInteger([params HTTPHeaderValueForContentLength], is(equalToInt(23166)));
    assertThat([[request.URLRequest allHTTPHeaderFields] objectForKey:@"Content-Length"], is(equalTo(@"23166")));
}

@end
