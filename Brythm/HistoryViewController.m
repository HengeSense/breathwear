//
//  HistoryViewController.m
//  Brythm
//
//  Created by Cassidy Robert Coyote Saenz on 12/7/12.
//  Copyright (c) 2012 Cassidy Robert Coyote Saenz. All rights reserved.
//

#import "HistoryViewController.h"
#import "BreathWearDatabase.h"
#import "BreathWearRecord.h"

#define DEFAULT_SESSION_ID 1328075662

#define FRAME_RATE 24.0
#define SEC_PER_PLOT 60
#define MAX_BREATH_RATE 20

#define DATA_DOWNSAMPLE_FACTOR 10

NSString *kDataPlotID = @"Data Plot";
NSString *kBaselinePlotID = @"Baseline Plot";


@interface HistoryViewController ()

@property (nonatomic, strong) BreathWearDatabase *db;
@property (nonatomic, strong) NSArray *breathrates;
@property (nonatomic, strong) NSMutableArray *plotData;
@property (nonatomic) int currentIndex;
@property (nonatomic) int sessionid;
@property (nonatomic) double initialTime;

@property (nonatomic, weak) CPTXYGraph *graph;
@property (nonatomic, weak) NSTimer *dataTimer;

@property (nonatomic, strong) NSMutableArray *InsightsXvalue;
@property (nonatomic, strong) NSMutableArray *InsightsYvalue;

// peaks
@property (nonatomic, strong) NSMutableArray *AllLocalPeaks; // record
@property (nonatomic, weak) NSTimer *delayTimer;
@property (nonatomic, weak) NSTimer *resumeTimer;

@end


@implementation HistoryViewController

@synthesize startTime = _startTime;
@synthesize endTime = _endTime;

@synthesize db = _db;
@synthesize breathrates = _breathrates;
@synthesize plotData = _plotData;
@synthesize currentIndex = _currentIndex;
@synthesize sessionid = _sessionid;
@synthesize initialTime = _initialTime;

@synthesize graph = _graph;
@synthesize dataTimer = _dataTimer;

@synthesize AllLocalPeaks = _AllLocalPeaks;
@synthesize InsightsXvalue = _InsightsXvalue;
@synthesize InsightsYvalue = _InsightsYvalue;

# pragma mark - Lazy Instantiation!

- (BreathWearDatabase *)db
{
    if (!_db)
        _db = [BreathWearDatabase getDatabase];
    return _db;
}

- (NSArray *)breathrates
{
    if (!_breathrates)
        _breathrates = [self.db getRecordsForSession:DEFAULT_SESSION_ID];
    return _breathrates;
}

- (NSMutableArray *)plotData
{
    if (!_plotData)
        _plotData = [[NSMutableArray alloc] initWithCapacity:SEC_PER_PLOT];
    return _plotData;
}

- (NSMutableArray *)AllLocalPeaks
{
    if (!_AllLocalPeaks)
        _AllLocalPeaks = [[NSMutableArray alloc] init];
    return _AllLocalPeaks;
}

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

- (void)preprocess
{
    // Downsample by DOWN_SAMPLE_FACTOR
    self.breathrates = [self.db getRecordsForSession:DEFAULT_SESSION_ID];
    NSMutableArray *breathratesTemp = [[NSMutableArray alloc] initWithCapacity:self.breathrates.count/DATA_DOWNSAMPLE_FACTOR];
    for (int i = 0; i < self.breathrates.count; i++) {
        if (i % DATA_DOWNSAMPLE_FACTOR == 0)
            [breathratesTemp addObject:[self.breathrates objectAtIndex:i]];
    }
    // Lowpass - average each record with previous record
    for (int i = 4; i < breathratesTemp.count; i++) {
        BreathWearRecord *curr = [breathratesTemp objectAtIndex:i];
        BreathWearRecord *prev1 = [breathratesTemp objectAtIndex:i-1];
        BreathWearRecord *prev2 = [breathratesTemp objectAtIndex:i-2];
        BreathWearRecord *prev3 = [breathratesTemp objectAtIndex:i-3];
        BreathWearRecord *prev4 = [breathratesTemp objectAtIndex:i-4];
        // filter coefficients found online (adjusted to keep average close to actual data)
        curr.breathRate = 0.07 * curr.breathRate + 0.25 * prev1.breathRate +
                0.365 * prev2.breathRate + 0.25 * prev3.breathRate + 0.07 * prev4.breathRate;
        [breathratesTemp replaceObjectAtIndex:i withObject:curr];
    }
    self.breathrates = [breathratesTemp copy];
}

- (void)findAllLocalPeaks
{
    for (int i = 1; i < self.breathrates.count-1; i++) {
        // Positive peaks
        BreathWearRecord *current = [self.breathrates objectAtIndex:i];
        BreathWearRecord *prev = [self.breathrates objectAtIndex:i-1];
        BreathWearRecord *next = [self.breathrates objectAtIndex:i+1];
        
        if (current.breathRate >= prev.breathRate && current.breathRate >= next.breathRate) {
            // we have a local max
            [self.AllLocalPeaks addObject:current];
        }
    }
}

- (void)findImportantLocalPeaks
{
    //self.localPeaks.
    //self.globalPeaks = 0;
}

- (void)findInterestingPoints // insights
{
    
}

# pragma mark - CPTPlotDataSource Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return self.plotData.count;
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)idx
{
    BreathWearRecord *record = [self.plotData objectAtIndex:idx];
    double val = record.breathRate;
    if (fieldEnum == CPTScatterPlotFieldX) {
        return [NSNumber numberWithDouble:(record.timestamp - record.sessionid - 64)];
    } else {
        if(plot.identifier == kDataPlotID)
            return [NSNumber numberWithDouble:val];
        else if (plot.identifier == kBaselinePlotID)
            return [NSNumber numberWithDouble:record.baselineRate];
        else
            return [NSNumber numberWithDouble:0.0];
    }
}

# pragma mark - Timer Callbacks

- (void)startDataTimer:(NSTimer *)timer
{
    self.dataTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/FRAME_RATE
                                                      target:self
                                                    selector:@selector(newData:)
                                                    userInfo:nil
                                                     repeats:YES];
}

- (void)focusOnInsight:(NSTimer *)timer
{
    [self.dataTimer invalidate];
    
    // Do stuff to focus on the insight, zoom, flashy stuff
    
    self.resumeTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                        target:self
                                                      selector:@selector(startDataTimer:)
                                                      userInfo:nil
                                                       repeats:NO];
}

- (void)newData:(NSTimer *)timer
{
    CPTScatterPlot *plot = (CPTScatterPlot *)[self.graph plotWithIdentifier:kDataPlotID];
    CPTScatterPlot *baseline = (CPTScatterPlot *)[self.graph plotWithIdentifier:kBaselinePlotID];
    
    if (plot && baseline) {
        BreathWearRecord *record = [self.breathrates objectAtIndex:self.currentIndex];
        double currTime = record.timestamp - record.sessionid - 64;
        
        if (currTime >= SEC_PER_PLOT) {
            [self.plotData removeObjectAtIndex:0];
            [plot deleteDataInIndexRange:NSMakeRange(0, 1)];
            [baseline deleteDataInIndexRange:NSMakeRange(0, 1)];
        }
        
        CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
        NSUInteger location = (currTime >= SEC_PER_PLOT ? (currTime - SEC_PER_PLOT) : 0);
        plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromUnsignedInteger(location)
                                                        length:CPTDecimalFromUnsignedInteger(SEC_PER_PLOT)];
        
        self.currentIndex += 1;
        if (self.currentIndex >= self.breathrates.count) {
            [self.dataTimer invalidate];
        } else if (self.currentIndex == 100) {
            self.delayTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                               target:self
                                                             selector:@selector(focusOnInsight:)
                                                             userInfo:nil
                                                              repeats:NO];
        } else {
            [self.plotData addObject:[self.breathrates objectAtIndex:self.currentIndex]];
            [plot insertDataAtIndex:self.plotData.count-1 numberOfRecords:1];
            [baseline insertDataAtIndex:self.plotData.count-1 numberOfRecords:1];
        }
    }
}

# pragma mark - ViewController Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // smooth out data and resample
    [self preprocess];
    
    self.currentIndex = 0;
    [self startDataTimer:nil];
    
    self.graph = [[CPTXYGraph alloc] initWithFrame:self.view.bounds];
    [self.graph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    
    CPTGraphHostingView *hostingView = (CPTGraphHostingView *)self.view;
    hostingView.hostedGraph = self.graph;
    self.graph.paddingLeft = 10.0;
    self.graph.paddingTop = 10.0;
    self.graph.paddingRight = 10.0;
    self.graph.paddingBottom = 10.0;
    self.graph.plotAreaFrame.paddingLeft = 60.0;
    self.graph.plotAreaFrame.paddingTop = 20.0;
    self.graph.plotAreaFrame.paddingRight = 20.0;
    self.graph.plotAreaFrame.paddingBottom = 50.0;
    
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0)
                                                    length:CPTDecimalFromFloat(SEC_PER_PLOT)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0)
                                                    length:CPTDecimalFromFloat(MAX_BREATH_RATE)];
    plotSpace.allowsUserInteraction = YES;
    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    
    CPTMutableLineStyle *lineStyle = [CPTLineStyle lineStyle];
    lineStyle.lineColor = [[CPTColor blackColor] colorWithAlphaComponent:0.7];
    lineStyle.lineWidth = 2.0f;
    
    axisSet.xAxis.majorIntervalLength = CPTDecimalFromUnsignedInteger(1);
    axisSet.xAxis.minorTicksPerInterval = 0;
    axisSet.xAxis.majorTickLineStyle = lineStyle;
    axisSet.xAxis.minorTickLineStyle = lineStyle;
    axisSet.xAxis.axisLineStyle = lineStyle;
    axisSet.xAxis.minorTickLength = 5.0f;
    axisSet.xAxis.majorTickLength = 7.0f;
    axisSet.xAxis.title = @"Time (seconds)";
    axisSet.xAxis.titleOffset = 25.0;
    axisSet.xAxis.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    
    axisSet.yAxis.majorIntervalLength = CPTDecimalFromUnsignedInteger(1);
    axisSet.yAxis.minorTicksPerInterval = 0;
    axisSet.yAxis.majorTickLineStyle = lineStyle;
    axisSet.yAxis.minorTickLineStyle = lineStyle;
    axisSet.yAxis.axisLineStyle = lineStyle;
    axisSet.yAxis.minorTickLength = 5.0f;
    axisSet.yAxis.majorTickLength = 7.0f;
    axisSet.yAxis.title = @"Breath Rate (bpm)";
    axisSet.yAxis.titleOffset = 35.0;
    axisSet.yAxis.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    axisSet.yAxis.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    
    CPTScatterPlot *plot = [[CPTScatterPlot alloc] init];
    plot.interpolation = CPTScatterPlotInterpolationCurved;
    plot.identifier = kDataPlotID;
    CPTMutableLineStyle *dataLineStyle1 = [CPTLineStyle lineStyle];
    dataLineStyle1.lineColor = [CPTColor colorWithComponentRed:0.7 green:0.2 blue:0.2 alpha:0.8];
    dataLineStyle1.lineWidth = 3.0f;
    plot.dataLineStyle = dataLineStyle1;
    plot.dataSource = self;
    [self.graph addPlot:plot];
    
    CPTScatterPlot *baseline = [[CPTScatterPlot alloc] init];
    baseline.identifier = kBaselinePlotID;
    CPTMutableLineStyle *dataLineStyle2 = [CPTLineStyle lineStyle];
    dataLineStyle2.lineColor = [[CPTColor greenColor] colorWithAlphaComponent:0.5];
    dataLineStyle2.lineWidth = 3.0f;
    baseline.dataLineStyle = dataLineStyle2;
    baseline.dataSource = self;
    [self.graph addPlot:baseline];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
