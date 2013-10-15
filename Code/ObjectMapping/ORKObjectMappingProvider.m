//
//  ORKObjectMappingProvider.m
//  RestKit
//
//  Created by Jeremy Ellison on 5/6/11.
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

#import "ORKObjectMappingProvider.h"
#import "ORKObjectMappingProvider+Contexts.h"
#import "ORKOrderedDictionary.h"
#import "ORKPathMatcher.h"
#import "ORKObjectMappingProviderContextEntry.h"
#import "ORKErrorMessage.h"

@implementation ORKObjectMappingProvider

+ (ORKObjectMappingProvider *)mappingProvider
{
    return [[self new] autorelease];
}

+ (ORKObjectMappingProvider *)mappingProviderUsingBlock:(void (^)(ORKObjectMappingProvider *mappingProvider))block
{
    ORKObjectMappingProvider *mappingProvider = [self mappingProvider];
    block(mappingProvider);
    return mappingProvider;
}

- (id)init
{
    self = [super init];
    if (self) {
        mappingContexts = [NSMutableDictionary new];
        [self initializeContext:ORKObjectMappingProviderContextObjectsByKeyPath withValue:[NSMutableDictionary dictionary]];
        [self initializeContext:ORKObjectMappingProviderContextObjectsByType withValue:[NSMutableArray array]];
        [self initializeContext:ORKObjectMappingProviderContextObjectsByResourcePathPattern withValue:[ORKOrderedDictionary dictionary]];
        [self initializeContext:ORKObjectMappingProviderContextSerialization withValue:[NSMutableDictionary dictionary]];
        [self initializeContext:ORKObjectMappingProviderContextErrors withValue:[NSNull null]];

        // Setup default error message mappings
        ORKObjectMapping *errorMapping = [ORKObjectMapping mappingForClass:[ORKErrorMessage class]];
        errorMapping.rootKeyPath = @"errors";
        [errorMapping mapKeyPath:@"" toAttribute:@"errorMessage"];
        self.errorMapping = errorMapping;
    }
    return self;
}

- (void)dealloc
{
    [mappingContexts release];
    [super dealloc];
}

- (void)setObjectMapping:(ORKObjectMappingDefinition *)objectOrDynamicMapping forKeyPath:(NSString *)keyPath
{
    [self setMapping:objectOrDynamicMapping forKeyPath:keyPath context:ORKObjectMappingProviderContextObjectsByKeyPath];
}

- (void)removeObjectMappingForKeyPath:(NSString *)keyPath
{
    [self removeMappingForKeyPath:keyPath context:ORKObjectMappingProviderContextObjectsByKeyPath];
}

- (ORKObjectMappingDefinition *)objectMappingForKeyPath:(NSString *)keyPath
{
    return [self mappingForKeyPath:keyPath context:ORKObjectMappingProviderContextObjectsByKeyPath];
}

- (void)setSerializationMapping:(ORKObjectMapping *)mapping forClass:(Class)objectClass
{
    [self setMapping:mapping forKeyPath:NSStringFromClass(objectClass) context:ORKObjectMappingProviderContextSerialization];
}

- (ORKObjectMapping *)serializationMappingForClass:(Class)objectClass
{
    return (ORKObjectMapping *)[self mappingForKeyPath:NSStringFromClass(objectClass) context:ORKObjectMappingProviderContextSerialization];
}

- (NSDictionary *)objectMappingsByKeyPath
{
    return [NSDictionary dictionaryWithDictionary:(NSDictionary *)[self valueForContext:ORKObjectMappingProviderContextObjectsByKeyPath]];
}

- (void)registerObjectMapping:(ORKObjectMapping *)objectMapping withRootKeyPath:(NSString *)keyPath
{
    // TODO: Should generate logs
    objectMapping.rootKeyPath = keyPath;
    [self setMapping:objectMapping forKeyPath:keyPath];
    ORKObjectMapping *inverseMapping = [objectMapping inverseMapping];
    inverseMapping.rootKeyPath = keyPath;
    [self setSerializationMapping:inverseMapping forClass:objectMapping.objectClass];
}

- (void)addObjectMapping:(ORKObjectMapping *)objectMapping
{
    [self addMapping:objectMapping context:ORKObjectMappingProviderContextObjectsByType];
}

- (NSArray *)objectMappingsForClass:(Class)theClass
{
    NSMutableArray *mappings = [NSMutableArray array];
    NSArray *mappingByType = [self valueForContext:ORKObjectMappingProviderContextObjectsByType];
    NSArray *mappingByKeyPath = [[self valueForContext:ORKObjectMappingProviderContextObjectsByKeyPath] allValues];
    NSArray *mappingsToSearch = [[NSArray arrayWithArray:mappingByType] arrayByAddingObjectsFromArray:mappingByKeyPath];
    for (ORKObjectMappingDefinition *candidateMapping in mappingsToSearch) {
        if (![candidateMapping respondsToSelector:@selector(objectClass)] || [mappings containsObject:candidateMapping])
            continue;
        Class mappedClass = [candidateMapping performSelector:@selector(objectClass)];
        if (mappedClass && [NSStringFromClass(mappedClass) isEqualToString:NSStringFromClass(theClass)]) {
            [mappings addObject:candidateMapping];
        }
    }
    return [NSArray arrayWithArray:mappings];
}

- (ORKObjectMapping *)objectMappingForClass:(Class)theClass
{
    NSArray *objectMappings = [self objectMappingsForClass:theClass];
    return ([objectMappings count] > 0) ? [objectMappings objectAtIndex:0] : nil;
}

#pragma mark - Error Mappings

- (ORKObjectMapping *)errorMapping
{
    return (ORKObjectMapping *)[self mappingForContext:ORKObjectMappingProviderContextErrors];
}

- (void)setErrorMapping:(ORKObjectMapping *)errorMapping
{
    if (errorMapping) {
        [self setMapping:errorMapping context:ORKObjectMappingProviderContextErrors];
    }
}

#pragma mark - Pagination Mapping

- (ORKObjectMapping *)paginationMapping
{
    return (ORKObjectMapping *)[self mappingForContext:ORKObjectMappingProviderContextPagination];
}

- (void)setPaginationMapping:(ORKObjectMapping *)paginationMapping
{
    [self setMapping:paginationMapping context:ORKObjectMappingProviderContextPagination];
}

- (void)setObjectMapping:(ORKObjectMappingDefinition *)objectMapping forResourcePathPattern:(NSString *)resourcePath
{
    [self setMapping:objectMapping forPattern:resourcePath context:ORKObjectMappingProviderContextObjectsByResourcePathPattern];
}

- (ORKObjectMappingDefinition *)objectMappingForResourcePath:(NSString *)resourcePath
{
    return [self mappingForPatternMatchingString:resourcePath context:ORKObjectMappingProviderContextObjectsByResourcePathPattern];
}

- (void)setEntry:(ORKObjectMappingProviderContextEntry *)entry forResourcePathPattern:(NSString *)resourcePath
{
    [self setEntry:entry forPattern:resourcePath context:ORKObjectMappingProviderContextObjectsByResourcePathPattern];
}

- (ORKObjectMappingProviderContextEntry *)entryForResourcePath:(NSString *)resourcePath
{
    return [self entryForPatternMatchingString:resourcePath context:ORKObjectMappingProviderContextObjectsByResourcePathPattern];
}

#pragma mark - Mapping Context Primitives

- (void)initializeContext:(ORKObjectMappingProviderContext)context withValue:(id)value
{
    NSAssert([self valueForContext:context] == nil, @"Attempt to reinitialized an existing mapping provider context.");
    [self setValue:value forContext:context];
}

- (id)valueForContext:(ORKObjectMappingProviderContext)context
{
    NSNumber *contextNumber = [NSNumber numberWithInteger:context];
    return [mappingContexts objectForKey:contextNumber];
}

- (void)setValue:(id)value forContext:(ORKObjectMappingProviderContext)context
{
    NSNumber *contextNumber = [NSNumber numberWithInteger:context];
    [mappingContexts setObject:value forKey:contextNumber];
}

- (void)assertStorageForContext:(ORKObjectMappingProviderContext)context isKindOfClass:(Class)theClass
{
    id contextValue = [self valueForContext:context];
    NSAssert([contextValue isKindOfClass:theClass], @"Storage type mismatch for context %d: expected a %@, got %@.", context, theClass, [contextValue class]);
}

- (void)setMapping:(ORKObjectMappingDefinition *)mapping context:(ORKObjectMappingProviderContext)context
{
    NSNumber *contextNumber = [NSNumber numberWithInteger:context];
    [mappingContexts setObject:mapping forKey:contextNumber];
}

- (ORKObjectMappingDefinition *)mappingForContext:(ORKObjectMappingProviderContext)context
{
    id contextValue = [self valueForContext:context];
    if ([contextValue isEqual:[NSNull null]]) return nil;
    Class class = [ORKObjectMappingDefinition class];
    NSAssert([contextValue isKindOfClass:class], @"Storage type mismatch for context %d: expected a %@, got %@.", context, class, [contextValue class]);
    return contextValue;
}

- (NSArray *)mappingsForContext:(ORKObjectMappingProviderContext)context
{
    id contextValue = [self valueForContext:context];
    if (contextValue == nil) return [NSArray array];
    [self assertStorageForContext:context isKindOfClass:[NSArray class]];

    return [NSArray arrayWithArray:contextValue];
}

- (void)addMapping:(ORKObjectMappingDefinition *)mapping context:(ORKObjectMappingProviderContext)context
{
    NSMutableArray *contextValue = [self valueForContext:context];
    if (contextValue == nil) {
        contextValue = [NSMutableArray arrayWithCapacity:1];
        [self setValue:contextValue forContext:context];
    }
    [self assertStorageForContext:context isKindOfClass:[NSArray class]];
    [contextValue addObject:mapping];
}

- (void)removeMapping:(ORKObjectMappingDefinition *)mapping context:(ORKObjectMappingProviderContext)context
{
    NSMutableArray *contextValue = [self valueForContext:context];
    NSAssert(contextValue, @"Attempted to remove mapping from undefined context: %d", context);
    [self assertStorageForContext:context isKindOfClass:[NSArray class]];
    NSAssert([contextValue containsObject:mapping], @"Attempted to remove mapping from collection that does not include it for context: %d", context);
    [contextValue removeObject:mapping];
}

- (ORKObjectMappingDefinition *)mappingForKeyPath:(NSString *)keyPath context:(ORKObjectMappingProviderContext)context
{
    NSMutableDictionary *contextValue = [self valueForContext:context];
    NSAssert(contextValue, @"Attempted to retrieve mapping from undefined context: %d", context);
    [self assertStorageForContext:context isKindOfClass:[NSDictionary class]];
    return [contextValue valueForKey:keyPath];
}

- (void)setMapping:(ORKObjectMappingDefinition *)mapping forKeyPath:(NSString *)keyPath context:(ORKObjectMappingProviderContext)context
{
    NSMutableDictionary *contextValue = [self valueForContext:context];
    if (contextValue == nil) {
        contextValue = [NSMutableDictionary dictionary];
        [self setValue:contextValue forContext:context];
    }
    [self assertStorageForContext:context isKindOfClass:[NSDictionary class]];
    [contextValue setValue:mapping forKey:keyPath];
}

- (void)removeMappingForKeyPath:(NSString *)keyPath context:(ORKObjectMappingProviderContext)context
{
    NSMutableDictionary *contextValue = [self valueForContext:context];
    [self assertStorageForContext:context isKindOfClass:[NSDictionary class]];
    [contextValue removeObjectForKey:keyPath];
}

- (void)setMapping:(ORKObjectMappingDefinition *)mapping forPattern:(NSString *)pattern atIndex:(NSUInteger)index context:(ORKObjectMappingProviderContext)context
{
    ORKOrderedDictionary *contextValue = [self valueForContext:context];
    if (contextValue == nil) {
        contextValue = [ORKOrderedDictionary dictionary];
        [self setValue:contextValue forContext:context];
    }
    [self assertStorageForContext:context isKindOfClass:[ORKOrderedDictionary class]];
    [contextValue insertObject:[ORKObjectMappingProviderContextEntry contextEntryWithMapping:mapping]
                        forKey:pattern
                       atIndex:index];
}

- (void)setMapping:(ORKObjectMappingDefinition *)mapping forPattern:(NSString *)pattern context:(ORKObjectMappingProviderContext)context
{
    ORKOrderedDictionary *contextValue = [self valueForContext:context];
    if (contextValue == nil) {
        contextValue = [ORKOrderedDictionary dictionary];
        [self setValue:contextValue forContext:context];
    }
    [self assertStorageForContext:context isKindOfClass:[ORKOrderedDictionary class]];
    [contextValue setObject:[ORKObjectMappingProviderContextEntry contextEntryWithMapping:mapping]
                     forKey:pattern];
}

- (ORKObjectMappingDefinition *)mappingForPatternMatchingString:(NSString *)string context:(ORKObjectMappingProviderContext)context
{
    NSAssert(string, @"Cannot look up mapping matching nil pattern string.");
    ORKOrderedDictionary *contextValue = [self valueForContext:context];
    NSAssert(contextValue, @"Attempted to retrieve mapping from undefined context: %d", context);
    for (NSString *pattern in contextValue) {
        ORKPathMatcher *pathMatcher = [ORKPathMatcher matcherWithPattern:pattern];
        if ([pathMatcher matchesPath:string tokenizeQueryStrings:NO parsedArguments:nil]) {
            ORKObjectMappingProviderContextEntry *entry = [contextValue objectForKey:pattern];
            return entry.mapping;
        }
    }

    return nil;
}

- (void)setEntry:(ORKObjectMappingProviderContextEntry *)entry forPattern:(NSString *)pattern context:(ORKObjectMappingProviderContext)context
{
    ORKOrderedDictionary *contextValue = [self valueForContext:context];
    if (contextValue == nil) {
        contextValue = [ORKOrderedDictionary dictionary];
        [self setValue:contextValue forContext:context];
    }
    [self assertStorageForContext:context isKindOfClass:[ORKOrderedDictionary class]];
    [contextValue setObject:entry
                     forKey:pattern];
}

- (ORKObjectMappingProviderContextEntry *)entryForPatternMatchingString:(NSString *)string context:(ORKObjectMappingProviderContext)context
{
    ORKOrderedDictionary *contextValue = [self valueForContext:context];
    NSAssert(contextValue, @"Attempted to retrieve mapping from undefined context: %d", context);
    for (NSString *pattern in contextValue) {
        ORKPathMatcher *pathMatcher = [ORKPathMatcher matcherWithPattern:pattern];
        if ([pathMatcher matchesPath:string tokenizeQueryStrings:NO parsedArguments:nil]) {
            return [contextValue objectForKey:pattern];
        }
    }

    return nil;
}

#pragma mark - Aliases

+ (ORKObjectMappingProvider *)objectMappingProvider
{
    return [self mappingProvider];
}

- (ORKObjectMapping *)mappingForKeyPath:(NSString *)keyPath
{
    return (ORKObjectMapping *)[self objectMappingForKeyPath:keyPath];
}

- (void)setMapping:(ORKObjectMapping *)mapping forKeyPath:(NSString *)keyPath
{
    [self setObjectMapping:mapping forKeyPath:keyPath];
}

- (NSDictionary *)mappingsByKeyPath
{
    return [self objectMappingsByKeyPath];
}

- (void)registerMapping:(ORKObjectMapping *)objectMapping withRootKeyPath:(NSString *)keyPath
{
    return [self registerObjectMapping:objectMapping withRootKeyPath:keyPath];
}

- (void)removeMappingForKeyPath:(NSString *)keyPath
{
    [self removeObjectMappingForKeyPath:keyPath];
}

// Deprecated
+ (id)mappingProviderWithBlock:(void (^)(ORKObjectMappingProvider *))block
{
    return [self mappingProviderUsingBlock:block];
}

@end
