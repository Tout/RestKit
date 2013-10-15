//
//  ORKJSONParserJSONKit.m
//  RestKit
//
//  Created by Jeff Arena on 3/16/10.
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

#import "ORKJSONParserJSONKit.h"
#import "JSONKit.h"
#import "ORKLog.h"

// Set Logging Component
#undef ORKLogComponent
#define ORKLogComponent lcl_cRestKitSupportParsers


// TODO: JSONKit serializer instance should be reused to enable leverage
// the internal caching capabilities from the JSONKit serializer
@implementation ORKJSONParserJSONKit

- (NSDictionary *)objectFromString:(NSString *)string error:(NSError **)error
{
    ORKLogTrace(@"string='%@'", string);
    return [string objectFromJSONStringWithParseOptions:JKParseOptionStrict error:error];
}

- (NSString *)stringFromObject:(id)object error:(NSError **)error
{
    return [object JSONStringWithOptions:JKSerializeOptionNone error:error];
}

@end
