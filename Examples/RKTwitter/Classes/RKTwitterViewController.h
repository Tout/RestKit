//
//  ORKTwitterViewController.h
//  ORKTwitter
//
//  Created by Blake Watters on 9/5/10.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RestKit/RestKit.h>

@interface ORKTwitterViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, ORKObjectLoaderDelegate> {
    UITableView *_tableView;
    NSArray *_statuses;
}

@end
