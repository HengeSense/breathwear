//
//  BrythmViewController.h
//  Brythm
//
//  Created by Cassidy Robert Coyote Saenz on 12/4/12.
//  Copyright (c) 2012 Cassidy Robert Coyote Saenz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BrythmViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate>

@property (nonatomic, weak) IBOutlet UIDatePicker *datePicker;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end
