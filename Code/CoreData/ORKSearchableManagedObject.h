//
//  ORKSearchableManagedObject.h
//  RestKit
//
//  Created by Jeff Arena on 3/31/11.
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

#import "NSManagedObject+ActiveRecord.h"
#import "ORKManagedObjectSearchEngine.h"

@class ORKSearchWord;

/**
 ORKSearchableManagedObject provides an abstract base class for Core Data entities
 that are searchable using the ORKManagedObjectSearchEngine interface. The collection of
 search words is maintained by the ORKSearchWordObserver singleton at managed object context
 save time.

 @see ORKSearchWord
 @see ORKSearchWordObserver
 @see ORKManagedObjectSearchEngine
 */
@interface ORKSearchableManagedObject : NSManagedObject

///-----------------------------------------------------------------------------
/// @name Configuring Searchable Attributes
///-----------------------------------------------------------------------------

/**
 Returns an array of attributes which should be processed by the search word observer to
 build the set of search words for entities with the type of the receiver. Subclasses must
 provide an implementation for indexing to occur as the base implementation returns an empty
 array.

 @warning *NOTE*: May only include attributes property names, not key paths.

 @return An array of attribute names containing searchable textual content for entities with the type of the receiver.
 @see ORKSearchWordObserver
 @see searchWords
 */
+ (NSArray *)searchableAttributes;

///-----------------------------------------------------------------------------
/// @name Obtaining a Search Predicate
///-----------------------------------------------------------------------------

/**
 A predicate that will search for the specified text with the specified mode. Mode can be
 configured to be ORKSearchModeAnd or ORKSearchModeOr.

 @return A predicate that will search for the specified text with the specified mode.
 @see ORKSearchMode
 */

+ (NSPredicate *)predicateForSearchWithText:(NSString *)searchText searchMode:(ORKSearchMode)mode;

///-----------------------------------------------------------------------------
/// @name Managing the Search Words
///-----------------------------------------------------------------------------

/**
 The set of tokenized search words contained in the receiver.
 */
@property (nonatomic, retain) NSSet *searchWords;

/**
 Rebuilds the set of tokenized search words associated with the receiver by processing the
 searchable attributes and tokenizing the contents into ORKSearchWord instances.

 @see [ORKSearchableManagedObject searchableAttributes]
 */
- (void)refreshSearchWords;

@end

@interface ORKSearchableManagedObject (SearchWordsAccessors)

/**
 Adds a search word object to the receiver's set of search words.

 @param searchWord The search word to be added to the set of search words.
 */
- (void)addSearchWordsObject:(ORKSearchWord *)searchWord;

/**
 Removes a search word object from the receiver's set of search words.

 @param searchWord The search word to be removed from the receiver's set of search words.
 */
- (void)removeSearchWordsObject:(ORKSearchWord *)searchWord;

/**
 Adds a set of search word objects to the receiver's set of search words.

 @param searchWords The set of search words to be added to receiver's the set of search words.
 */
- (void)addSearchWords:(NSSet *)searchWords;

/**
 Removes a set of search word objects from the receiver's set of search words.

 @param searchWords The set of search words to be removed from receiver's the set of search words.
 */
- (void)removeSearchWords:(NSSet *)searchWords;

@end
