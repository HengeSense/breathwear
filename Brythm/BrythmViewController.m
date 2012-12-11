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

@property (nonatomic, strong) NSString *startDate;
@property (nonatomic, strong) NSString *endDate;
@property (nonatomic) int currentSelectedCell;
@property (nonatomic, strong) NSMutableArray *timewas;

@end


@implementation BrythmViewController
@synthesize datePicker = _datePicker;
@synthesize tableView = _tableView;
@synthesize currentSelectedCell = _currentSelectedCell;

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

- (void)viewDidLoad {
    [super viewDidLoad];
	self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.currentSelectedCell = 0;
	//Use NSDateFormatter to write out the date in a friendly format
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	[df setTimeStyle:NSDateFormatterShortStyle];
    [df setDateStyle:NSDateFormatterMediumStyle];
	self.startDate = [NSString stringWithFormat:@"%@",
                  [df stringFromDate:[NSDate date]]];
	
	// Initialization code
	self.datePicker.date = [NSDate date];
	[self.datePicker addTarget:self
                   action:@selector(changeDateInLabel:)
         forControlEvents:UIControlEventValueChanged];
}

- (void)changeDateInLabel:(id)sender{
	//Use NSDateFormatter to write out the date in a friendly format
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	[df setTimeStyle:NSDateFormatterShortStyle];
    [df setDateStyle:NSDateFormatterMediumStyle];
    if (self.currentSelectedCell == 0) {
        self.startDate = [NSString stringWithFormat:@"%@",
                          [df stringFromDate:self.datePicker.date]];
    } else if (self.currentSelectedCell == 1) {
        self.endDate = [NSString stringWithFormat:@"%@",
                          [df stringFromDate:self.datePicker.date]];
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
    self.currentSelectedCell = indexPath.row;
    
    if (indexPath.row == 1) {
        // end
    }
    // Navigation logic may go here. Create and push another view controller.
    if (indexPath.row == 2) {
        HistoryViewController *detailViewController = [[HistoryViewController alloc] init];
        // ...
        // Pass the selected object to the new view controller.
        //[self.navigationController pushViewController:detailViewController animated:YES];
        [self performSegueWithIdentifier:@"graph" sender:self];
    }
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
    
    if (indexPath.row == 0) {
        // start
        cell.textLabel.text = @"Starts";
        cell.detailTextLabel.text = self.startDate;
        if (self.currentSelectedCell == 0) {
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }
    } else if (indexPath.row == 1) {
        // end
        cell.textLabel.text = @"Ends";
        cell.detailTextLabel.text = self.endDate;
        if (self.currentSelectedCell == 0) {
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }

    } else {
        // graph
        cell.textLabel.text = @"Graph";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

@end
