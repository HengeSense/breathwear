//
//  BrythmViewController.m
//  Brythm
//
//  Created by Cassidy Robert Coyote Saenz on 12/4/12.
//  Copyright (c) 2012 Cassidy Robert Coyote Saenz. All rights reserved.
//

#import "BrythmViewController.h"
#import "HistoryViewController.h"
#define CENTER 1328392510


@interface BrythmViewController ()

@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic) int currentSelectedCell;
@property (nonatomic) int previousSelectedCell;

@end


@implementation BrythmViewController
@synthesize datePicker = _datePicker;
@synthesize tableView = _tableView;
@synthesize currentSelectedCell = _currentSelectedCell;
@synthesize previousSelectedCell = _previousSelectedCell;
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
    hvc.startTime = [self.startDate timeIntervalSince1970];
    hvc.endTime = [self.endDate timeIntervalSince1970];
}

# pragma mark - ViewController Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
	self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.currentSelectedCell = 0;
    self.previousSelectedCell = 0;
	//Use NSDateFormatter to write out the date in a friendly format
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	[df setTimeStyle:NSDateFormatterShortStyle];
    [df setDateStyle:NSDateFormatterMediumStyle];
	
    self.startDate = [NSDate dateWithTimeIntervalSince1970:CENTER];
	// Initialization code
	
    self.datePicker.date = [NSDate dateWithTimeIntervalSince1970:CENTER];
	[self.datePicker addTarget:self
                   action:@selector(changeDateInLabel:)
         forControlEvents:UIControlEventValueChanged];
}

- (BOOL)checkDatesRange
{
    BOOL okay = NO;
    
    if ([self.startDate compare:self.endDate] == NSOrderedAscending) {
        okay = YES;
    }
    
    if (okay == NO) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"End time must be greater than Start time" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    return okay;
}

- (void)changeDateInLabel:(id)sender{
	//Use NSDateFormatter to write out the date in a friendly format
    
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	[df setTimeStyle:NSDateFormatterShortStyle];
    [df setDateStyle:NSDateFormatterMediumStyle];
    if (self.currentSelectedCell == 2) {
        self.currentSelectedCell = self.previousSelectedCell;
    }
    if (self.currentSelectedCell == 0) {
        self.startDate = self.datePicker.date;
    } else if (self.currentSelectedCell == 1){
        self.endDate = self.datePicker.date;
    }
    NSLog(@"Start date %@", self.startDate);
    [self.tableView reloadData];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark - Table View Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehaviorDefault];
    //[dateFormatter setDateFormat:@"EEE, MMM dd yyyy HH:mm ZZ"];
    [dateFormatter setDateFormat:@"MMM dd',' yyyy',' h:mm ZZ"];
    //[dateFormatter setDateFormat:@"dd-MM-yyyy"];
    //[dateFormatter setDateFormat:@"dd-MM-yyyy"];
    NSLocale *loc = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setLocale:loc];
    //[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    self.previousSelectedCell = self.currentSelectedCell;
    self.currentSelectedCell = indexPath.row;
    //UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.row == 0) {
        //self.datePicker.date = [dateFormatter dateFromString:@"01-02-2010"];
        //self.datePicker.date = [dateFormatter dateFromString:self.startDate];
        //self.datePicker.date = [dateFormatter dateFromString:@"Dec 23, 2012, 11:23 PM"];
    }
    if (indexPath.row == 1) {
        // end
        if (self.endDate) {
            //[self.datePicker setDate:[dateFormatter dateFromString:self.endDate]];
        } else {
            // add one more hour to the start date
            /// NSDate *startDate = [dateFormatter dateFromString:self.startDate];
            //NSLog(@"date from string: %@", [startDate description]);
            //NSDate *endDate = (NSDate *)[NSDate dateWithTimeInterval:3600.0 sinceDate:[NSDate date]];
            //[self.datePicker setDate:[dateFormatter dateFromString:[endDate description]]];
            //[self.datePicker setDate:endDate];

        }
    }
    // Navigation logic may go here. Create and push another view controller.
    if (indexPath.row == 2) {
        //HistoryViewController *detailViewController = [[HistoryViewController alloc] init];
        // ...
        // Pass the selected object to the new view controller.
        //[self.navigationController pushViewController:detailViewController animated:YES];
        if ([self checkBeforeSegue]) {
            [self performSegueWithIdentifier:@"graph" sender:self];
        }
    }
}

- (BOOL)checkBeforeSegue
{
    if (self.endDate == nil) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"You forgot to choose an End Time" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return NO;
    }
    if (self.startDate == nil)  {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"You forgot to choose a Start Time" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return NO;
    }
    // Make sure the Date range makes sense
    return [self checkDatesRange];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 3;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        
       cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
       cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        
    }
    // Configure the cell...
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
	[df setTimeStyle:NSDateFormatterShortStyle];
    [df setDateStyle:NSDateFormatterMediumStyle];
    
    if (indexPath.row == 0) {
        // start
        cell.textLabel.text = @"Starts";
        cell.detailTextLabel.text = [df stringFromDate:self.startDate];
        if (self.currentSelectedCell == 0) {
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }
    } else if (indexPath.row == 1) {
        // end
        cell.textLabel.text = @"Ends";
        cell.detailTextLabel.text = [df stringFromDate:self.endDate];
        if (self.currentSelectedCell == 0) {
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }

    } else {
        // graph
        cell.textLabel.text = @"Graph";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return cell;
}

@end
