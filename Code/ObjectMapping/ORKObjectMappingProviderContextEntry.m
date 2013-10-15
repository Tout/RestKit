//
//  ORKObjectMappingProviderContextEntry.m
//  RestKit
//
//  Created by Jeff Arena on 1/26/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "ORKObjectMappingProviderContextEntry.h"

@implementation ORKObjectMappingProviderContextEntry

@synthesize mapping = _mapping;
@synthesize userData = _userData;

- (id)init
{
    self = [super init];
    if (self) {
        _mapping = nil;
        _userData = nil;
    }
    return self;
}

- (void)dealloc
{
    [_mapping release];
    _mapping = nil;
    [_userData release];
    _userData = nil;
    [super dealloc];
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[ORKObjectMappingProviderContextEntry class]]) {
        ORKObjectMappingProviderContextEntry *entry = (ORKObjectMappingProviderContextEntry *)object;
        return ([self.mapping isEqual:entry.mapping] && (self.userData == entry.userData));
    }
    return NO;
}

- (NSUInteger)hash
{
    int prime = 31;
    int result = 1;
    result = prime *[self.userData hash] ? [self.mapping hash] : [self.userData hash];
    return result;
}

+ (ORKObjectMappingProviderContextEntry *)contextEntryWithMapping:(ORKObjectMappingDefinition *)mapping
{
    ORKObjectMappingProviderContextEntry *contextEntry = [[[ORKObjectMappingProviderContextEntry alloc] init] autorelease];
    contextEntry.mapping = mapping;
    return contextEntry;
}

+ (ORKObjectMappingProviderContextEntry *)contextEntryWithMapping:(ORKObjectMappingDefinition *)mapping userData:(id)userData
{
    ORKObjectMappingProviderContextEntry *contextEntry = [ORKObjectMappingProviderContextEntry contextEntryWithMapping:mapping];
    contextEntry.userData = userData;
    return contextEntry;
}

@end
