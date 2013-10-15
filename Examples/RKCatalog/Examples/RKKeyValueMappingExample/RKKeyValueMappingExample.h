//
//  ORKKeyValueMappingExample.h
//  ORKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "ORKCatalog.h"

@interface ORKKeyValueMappingExample : UIViewController <ORKObjectLoaderDelegate> {
    UILabel *_infoLabel;
}

@property (nonatomic, retain) IBOutlet UILabel *infoLabel;

@end
