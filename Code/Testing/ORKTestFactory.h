//
//  ORKTestFactory.h
//  ORKGithub
//
//  Created by Blake Watters on 2/16/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <RestKit/RestKit.h>

/**
 The default filename used for managed object stores created via the factory.

 @see [ORKTestFactory setManagedObjectStoreFilename:]
 */
extern NSString * const ORKTestFactoryDefaultStoreFilename;

/**
 Defines optional callback methods for extending the functionality of the
 factory. Implementation can be provided via a category.

 @see ORKTestFactory
 */
@protocol ORKTestFactoryCallbacks <NSObject>

@optional

///-----------------------------------------------------------------------------
/// @name Customizing the Factory
///-----------------------------------------------------------------------------

/**
 Application specific initialization point for the factory.
 Called once per unit testing run when the factory singleton instance is initialized. RestKit
 applications may override via a category.
 */
+ (void)didInitialize;

/**
 Application specific customization point for the factory.
 Invoked each time the factory is asked to set up the environment. RestKit applications
 leveraging the factory may override via a category.
 */
+ (void)didSetUp;

/**
 Application specific customization point for the factory.
 Invoked each time the factory is tearing down the environment. RestKit applications
 leveraging the factory may override via a category.
 */
+ (void)didTearDown;

@end

/*
 Default Factory Names
 */
extern NSString * const ORKTestFactoryDefaultNamesClient;
extern NSString * const ORKTestFactoryDefaultNamesObjectManager;
extern NSString * const ORKTestFactoryDefaultNamesMappingProvider;
extern NSString * const ORKTestFactoryDefaultNamesManagedObjectStore;

/**
 ORKTestFactory provides an interface for initializing RestKit
 objects within a unit testing environment. The factory is used to ensure isolation
 between test cases by ensuring that RestKit's important singleton objects are torn
 down between tests and that each test is working within a clean Core Data environment.
 Callback hooks are provided so that application specific set up and tear down logic can be
 integrated as well.

 The factory also provides for the definition of named factories for instantiating objects
 quickly. At initialization, there are factories defined for creating instances of ORKClient,
 ORKObjectManager, ORKObjectMappingProvider, and ORKManagedObjectStore. These factories may be
 redefined within your application should you choose to utilize a subclass or wish to centralize
 configuration of objects across the test suite. You may also define additional factories for building
 instances of objects specific to your application using the same infrastructure.
 */
@interface ORKTestFactory : NSObject <ORKTestFactoryCallbacks>

///-----------------------------------------------------------------------------
/// @name Configuring the Factory
///-----------------------------------------------------------------------------

/**
 Returns the base URL with which to initialize ORKClient and ORKObjectManager
 instances created via the factory.

 @return The base URL for the factory.
 */
+ (ORKURL *)baseURL;

/**
 Sets the base URL for the factory.

 @param URL The new base URL.
 */
+ (void)setBaseURL:(ORKURL *)URL;

/**
 Returns the base URL as a string value.

 @return The base URL for the factory, as a string.
 */
+ (NSString *)baseURLString;

/**
 Sets the base URL for the factory to a new value by constructing an ORKURL
 from the given string.

 @param baseURLString A string containing the URL to set as the base URL for the factory.
 */
+ (void)setBaseURLString:(NSString *)baseURLString;

/**
 Returns the filename used when constructing instances of ORKManagedObjectStore
 via the factory.

 @return A string containing the filename to use when creating a managed object store.
 */
+ (NSString *)managedObjectStoreFilename;

/**
 Sets the filename to use when the factory constructs an instance of ORKManagedObjectStore.

 @param managedObjectStoreFilename A string containing the filename to use when creating managed object
 store instances.
 */
+ (void)setManagedObjectStoreFilename:(NSString *)managedObjectStoreFilename;

///-----------------------------------------------------------------------------
/// @name Defining & Instantiating Objects from Factories
///-----------------------------------------------------------------------------

/**
 Defines a factory with a given name for building object instances using the
 given block. When the factory singleton receives an objectFromFactory: message,
 the block designated for the given factory name is invoked and the resulting object
 reference is returned.

 Existing factories can be invoking defineFactory:withBlock: with an existing factory name.

 @param factoryName The name to assign the factory.
 @param block A block to execute when building an object instance for the factory name.
 @return A configured object instance.
 */
+ (void)defineFactory:(NSString *)factoryName withBlock:(id (^)())block;

/**
 Creates and returns a new instance of an object using the factory with the given
 name.

 @param factoryName The name of the factory to use when building the requested object.
 @raises NSInvalidArgumentException Raised if a factory with the given name is not defined.
 @return An object built using the factory registered for the given name.
 */
+ (id)objectFromFactory:(NSString *)factoryName;

/**
 Returns a set of names for all defined factories.

 @return A set of the string names for all defined factories.
 */
+ (NSSet *)factoryNames;

///-----------------------------------------------------------------------------
/// @name Building Instances
///-----------------------------------------------------------------------------

/**
 Creates and returns an ORKClient instance using the factory defined
 for the name ORKTestFactoryDefaultNamesClient.

 @return A new client instance.
 */
+ (id)client;

/**
 Creates and returns an ORKObjectManager instance using the factory defined
 for the name ORKTestFactoryDefaultNamesObjectManager.

 @return A new object manager instance.
 */
+ (id)objectManager;

/**
 Creates and returns an ORKObjectMappingProvider instance using the factory defined
 for the name ORKTestFactoryDefaultNamesMappingProvider.

 @return A new object mapping provider instance.
 */
+ (id)mappingProvider;

/**
 Creates and returns a ORKManagedObjectStore instance using the factory defined
 for the name ORKTestFactoryDefaultNamesManagedObjectStore.

 A new managed object store will be configured and returned. If there is an existing
 persistent store (i.e. from a previous test invocation), then the persistent store
 is deleted.

 @return A new managed object store instance.
 */
+ (id)managedObjectStore;

///-----------------------------------------------------------------------------
/// @name Managing Test State
///-----------------------------------------------------------------------------

/**
 Sets up the RestKit testing environment. Invokes the didSetUp callback for application
 specific setup.
 */
+ (void)setUp;

/**
 Tears down the RestKit testing environment by clearing singleton instances, helping to
 ensure test case isolation. Invokes the didTearDown callback for application specific
 cleanup.
 */
+ (void)tearDown;

///-----------------------------------------------------------------------------
/// @name Other Tasks
///-----------------------------------------------------------------------------

/**
 Clears the contents of the cache directory by removing the directory and
 recreating it.

 @see [ORKDirectory cachesDirectory]
 */
+ (void)clearCacheDirectory;

@end
