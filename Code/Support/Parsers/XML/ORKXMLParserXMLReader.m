//
//  ORKXMLParserXMLReader.m
//  RestKit
//
//  Created by Christopher Swasey on 1/24/12.
//  Copyright (c) 2012 GateGuru. All rights reserved.
//

#import "ORKXMLParserXMLReader.h"

@implementation ORKXMLParserXMLReader

- (id)objectFromString:(NSString *)string error:(NSError **)error
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [XMLReader dictionaryForXMLData:data error:error];
}

- (NSString *)stringFromObject:(id)object error:(NSError **)error
{
    return nil;
}

@end
