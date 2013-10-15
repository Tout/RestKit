//
//  ORKTableController.h
//  RestKit
//
//  Created by Blake Watters on 8/1/11.
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

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import "ORKAbstractTableController.h"
#import "ORKTableSection.h"
#import "ORKTableViewCellMappings.h"
#import "ORKTableItem.h"
#import "ORKForm.h"
#import "ORKObjectManager.h"
#import "ORKObjectMapping.h"
#import "ORKObjectLoader.h"

@protocol ORKTableControllerDelegate <ORKAbstractTableControllerDelegate>

@optional

- (void)tableController:(ORKTableController *)tableController didLoadObjects:(NSArray *)objects inSection:(ORKTableSection *)section;

@end

@interface ORKTableController : ORKAbstractTableController

@property (nonatomic, assign) id<ORKTableControllerDelegate> delegate;

///-----------------------------------------------------------------------------
/// @name Static Tables
///-----------------------------------------------------------------------------

- (void)loadObjects:(NSArray *)objects;
- (void)loadObjects:(NSArray *)objects inSection:(NSUInteger)sectionIndex;
- (void)loadEmpty;

/**
 Load an array of ORKTableItems into table cells of the specified class. A table cell
 mapping will be constructed on your behalf and yielded to the block for configuration.
 After the block is invoked, the objects will be loaded into the specified section.
 */
// TODO: Update comments...
- (void)loadTableItems:(NSArray *)tableItems withMapping:(ORKTableViewCellMapping *)cellMapping;
- (void)loadTableItems:(NSArray *)tableItems
             inSection:(NSUInteger)sectionIndex
           withMapping:(ORKTableViewCellMapping *)cellMapping;

/**
 Load an array of ORKTableItem objects into the table using the default
 ORKTableViewCellMapping. An instance of the cell mapping will be created on your
 behalf and configured with the default table view cell attribute mappings.

 @param tableItems An array of ORKTableItem instances to load into the table

 @see ORKTableItem
 @see [ORKTableViewCellMapping addDefaultMappings]
 */
- (void)loadTableItems:(NSArray *)tableItems;

/**
 Load an array of ORKTableItem objects into the specified section with the table using the default
 ORKTableViewCellMapping. An instance of the cell mapping will be created on your
 behalf and configured with the default table view cell attribute mappings.

 @param tableItems An array of ORKTableItem instances to load into the table
 @param sectionIndex The section to load the table items into. Must be less than sectionCount.

 @see ORKTableItem
 @see [ORKTableViewCellMapping addDefaultMappings]
 */
- (void)loadTableItems:(NSArray *)tableItems inSection:(NSUInteger)sectionIndex;

///-----------------------------------------------------------------------------
/** @name Network Tables */
///-----------------------------------------------------------------------------

- (void)loadTableFromResourcePath:(NSString *)resourcePath;
- (void)loadTableFromResourcePath:(NSString *)resourcePath usingBlock:(void (^)(ORKObjectLoader *objectLoader))block;

///-----------------------------------------------------------------------------
/** @name Forms */
///-----------------------------------------------------------------------------

/**
 The form that the table has been loaded with (if any)
 */
@property (nonatomic, retain, readonly) ORKForm *form;

/**
 Loads the table with the contents of the specified form object.
 Forms are used to build content entry and editing interfaces for objects.

 @see ORKForm
 */
- (void)loadForm:(ORKForm *)form;

///-----------------------------------------------------------------------------
/// @name Managing Sections
///-----------------------------------------------------------------------------

@property (nonatomic, readonly) NSMutableArray *sections;

/**
 The key path on the loaded objects used to determine the section they belong to.
 */
@property (nonatomic, copy) NSString *sectionNameKeyPath;

/**
 Returns the section at the specified index.
 @param index Must be less than the total number of sections.
 */
- (ORKTableSection *)sectionAtIndex:(NSUInteger)index;

/**
 Returns the first section with the specified header title.
 @param title The header title.
 */
- (ORKTableSection *)sectionWithHeaderTitle:(NSString *)title;

/**
 Returns the index of the specified section.

 @param section Must be a valid non nil ORKTableViewSection.
 @return The index of the given section if contained within the receiver, otherwise NSNotFound.
 */
- (NSUInteger)indexForSection:(ORKTableSection *)section;

// Coalesces a series of table view updates performed within the block into
// a single animation using beginUpdates: and endUpdates: on the table view
// TODO: Move to super-class?
- (void)updateTableViewUsingBlock:(void (^)())block;

/** Adds a new section to the model.
 * @param section Must be a valid non nil ORKTableViewSection. */
// NOTE: connects cellMappings if section.cellMappings is nil...
- (void)addSection:(ORKTableSection *)section;

/** Inserts a new section at the specified index.
 * @param section Must be a valid non nil ORKTableViewSection.
 * @param index Must be less than the total number of sections. */
- (void)insertSection:(ORKTableSection *)section atIndex:(NSUInteger)index;

/** Removes the specified section from the model.
 * @param section The section to remove. */
- (void)removeSection:(ORKTableSection *)section;

/** Removes the section at the specified index from the model.
 * @param index Must be less than the total number of section. */
- (void)removeSectionAtIndex:(NSUInteger)index;

/** Removes all sections from the model. */
// NOTE: Adds a new section 0
- (void)removeAllSections;
- (void)removeAllSections:(BOOL)recreateFirstSection;

@end

#endif // TARGET_OS_IPHONE
