//
//  ORKReachabilityExample.h
//  ORKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "ORKCatalog.h"

@interface ORKReachabilityExample : UIViewController {
    ORKReachabilityObserver *_observer;
    UILabel *_statusLabel;
    UILabel *_flagsLabel;
}

@property (nonatomic, retain) ORKReachabilityObserver *observer;
@property (nonatomic, retain) IBOutlet UILabel *statusLabel;
@property (nonatomic, retain) IBOutlet UILabel *flagsLabel;

@end
