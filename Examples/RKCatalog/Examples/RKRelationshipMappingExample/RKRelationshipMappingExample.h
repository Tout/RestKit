//
//  ORKRelationshipMappingExample.h
//  ORKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "ORKCatalog.h"
#import "Project.h"

@interface ORKRelationshipMappingExample : UITableViewController <ORKObjectLoaderDelegate, UITableViewDelegate> {
    Project *_selectedProject;
    NSArray *_objects;
}

@end
