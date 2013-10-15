//
//  ORKObjectMappingProvider.m
//  RestKit
//
//  Created by Blake Watters on 1/17/12.
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

// Contexts provide primitives for managing collections of object mappings namespaced
// within a single mapping provider. This enables easy reuse and extension via categories.
@interface ORKObjectMappingProvider (Contexts)

- (void)initializeContext:(ORKObjectMappingProviderContext)context withValue:(id)value;
- (id)valueForContext:(ORKObjectMappingProviderContext)context;
- (void)setValue:(id)value forContext:(ORKObjectMappingProviderContext)context;

- (ORKObjectMappingDefinition *)mappingForContext:(ORKObjectMappingProviderContext)context;
/**
 Stores a single object mapping for a given context. Useful when a component needs to enable
 configuration via one (and only one) object mapping.
 */
- (void)setMapping:(ORKObjectMappingDefinition *)mapping context:(ORKObjectMappingProviderContext)context;
- (NSArray *)mappingsForContext:(ORKObjectMappingProviderContext)context;
- (void)addMapping:(ORKObjectMappingDefinition *)mapping context:(ORKObjectMappingProviderContext)context;
- (void)removeMapping:(ORKObjectMappingDefinition *)mapping context:(ORKObjectMappingProviderContext)context;
- (ORKObjectMappingDefinition *)mappingForKeyPath:(NSString *)keyPath context:(ORKObjectMappingProviderContext)context;
- (void)setMapping:(ORKObjectMappingDefinition *)mapping forKeyPath:(NSString *)keyPath context:(ORKObjectMappingProviderContext)context;
- (void)removeMappingForKeyPath:(NSString *)keyPath context:(ORKObjectMappingProviderContext)context;

- (void)setMapping:(ORKObjectMappingDefinition *)mapping forPattern:(NSString *)pattern atIndex:(NSUInteger)index context:(ORKObjectMappingProviderContext)context;
- (void)setMapping:(ORKObjectMappingDefinition *)mapping forPattern:(NSString *)pattern context:(ORKObjectMappingProviderContext)context;
- (ORKObjectMappingDefinition *)mappingForPatternMatchingString:(NSString *)string context:(ORKObjectMappingProviderContext)context;
- (void)setEntry:(ORKObjectMappingProviderContextEntry *)entry forPattern:(NSString *)pattern context:(ORKObjectMappingProviderContext)context;
- (ORKObjectMappingProviderContextEntry *)entryForPatternMatchingString:(NSString *)string context:(ORKObjectMappingProviderContext)context;

@end
