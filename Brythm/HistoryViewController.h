//
//  HistoryViewController.h
//  Brythm
//
//  Created by Cassidy Robert Coyote Saenz on 12/7/12.
//  Copyright (c) 2012 Cassidy Robert Coyote Saenz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CorePlot-CocoaTouch.h"

@interface HistoryViewController : UIViewController <CPTPlotDataSource>

@property (nonatomic) int startTime;
@property (nonatomic) int endTime;
@property (nonatomic) int windowIntervalLength; // in seconds

@end
