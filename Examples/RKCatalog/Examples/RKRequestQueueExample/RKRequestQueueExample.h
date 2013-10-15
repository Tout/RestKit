//
//  ORKRequestQueueExample.h
//  ORKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "ORKCatalog.h"

@interface ORKRequestQueueExample : UIViewController <ORKRequestQueueDelegate, ORKRequestDelegate>

@property (nonatomic, retain) ORKRequestQueue *requestQueue;
@property (nonatomic, retain) IBOutlet UILabel *statusLabel;

- (IBAction)sendRequest;
- (IBAction)queueRequests;

@end
