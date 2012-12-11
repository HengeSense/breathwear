//
//  BrythmViewController.m
//  Brythm
//
//  Created by Cassidy Robert Coyote Saenz on 12/4/12.
//  Copyright (c) 2012 Cassidy Robert Coyote Saenz. All rights reserved.
//

#import "BrythmViewController.h"
#import "HistoryViewController.h"


@interface BrythmViewController ()

@end


@implementation BrythmViewController

/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
 */
/*
# pragma mark - CPTPlotDataSource Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return self.breathrates.count;
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)idx
{
    BreathWearRecord *record = [self.breathrates objectAtIndex:idx];
    double val = record.breathRate;
    if(fieldEnum == CPTScatterPlotFieldX)
    {
        double x = record.timestamp - (double)record.sessionid - 60.0;
        printf("%f\n", record.timestamp);
        return [NSNumber numberWithDouble:x];
    }
    else
    {
        //printf("%f\n", val);
        if(plot.identifier == @"Main Plot")
        { return [NSNumber numberWithDouble:val]; }
        else
        { return [NSNumber numberWithDouble:0]; }
    }
}
 */

# pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    HistoryViewController *hvc = (HistoryViewController *)segue.destinationViewController;
    // pass user-chosen data to HistoryViewController
}

# pragma mark - ViewController Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Custom ish
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
