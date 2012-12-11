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

#define FRAME_RATE 30.0
#define SEC_PER_PLOT 600
#define MAX_BREATH_RATE 20

#define DATA_DOWNSAMPLE_FACTOR 10

#define INSIGHT_PAUSE_TIME 3.0

NSString *kDataPlotID = @"You";
NSString *kBaselinePlotID = @"Your Goal";


@interface HistoryViewController ()

@property (nonatomic, strong) BreathWearDatabase *db;
@property (nonatomic, strong) NSArray *breathrates;
@property (nonatomic, strong) NSMutableArray *plotData;
@property (nonatomic) int currentIndex;
@property (nonatomic) int sessionid;
@property (nonatomic) double dataDelay;

@property (nonatomic, weak) CPTXYGraph *graph;
@property (nonatomic, weak) NSTimer *dataTimer;

//@property (nonatomic, strong) NSMutableArray *InsightsXvalue;
//@property (nonatomic, strong) NSMutableArray *InsightsYvalue;

// peaks
//@property (nonatomic, strong) NSMutableArray *AllLocalPeaks; // record
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
@synthesize dataDelay = _dataDelay;

@synthesize graph = _graph;
@synthesize dataTimer = _dataTimer;

//@synthesize AllLocalPeaks = _AllLocalPeaks;
//@synthesize InsightsXvalue = _InsightsXvalue;
//@synthesize InsightsYvalue = _InsightsYvalue;

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
    // Determine delay in recorded data
    BreathWearRecord *firstRecord = [self.breathrates objectAtIndex:0];
    self.dataDelay = firstRecord.timestamp - firstRecord.sessionid;
    
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

/* OLD PRE-PROCESSING STEP TO FIND INSIGHTS
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
*/

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
        return [NSNumber numberWithDouble:(record.timestamp - record.sessionid - self.dataDelay)];
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
    // restore interaction in case it was disabled by an insight event
    self.graph.defaultPlotSpace.allowsUserInteraction = YES;
    // remove any previously posted annotations
    [self.graph.plotAreaFrame.plotArea removeAllAnnotations];
    // begin animation timer
    self.dataTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/FRAME_RATE
                                                      target:self
                                                    selector:@selector(newData:)
                                                    userInfo:nil
                                                     repeats:YES];
}

- (void)focusOnInsight:(NSTimer *)timer
{
    [self.dataTimer invalidate];
    // pause interaction when focusing on insight
    self.graph.defaultPlotSpace.allowsUserInteraction = NO;
    
    // post an annotation around the insightful record
    //BreathWearRecord *insight = [timer.userInfo objectForKey:@"record"];
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    textStyle.color    = [[CPTColor greenColor] colorWithAlphaComponent:0.7];
    textStyle.fontSize = 12.0;
    textStyle.fontName = @"Helvetica-Bold";
    
    NSString *annText;
    switch ([[timer.userInfo objectForKey:@"index"] integerValue]) {
        case 200:
            annText = @"*Did the app stress you out? Sorry :)";
            break;
        case 310:
            annText = @"+Recovery!  What calmed you here?";
            break;
        case 450:
            annText = @"*Stressed again?  Maybe it was just something exciting!";
            break;
        case 550:
            annText = @"+Sure is a rollercoaster ride, huh?";
            break;
        case 750:
            annText = @"+Great job!  What were you doing during this calm period?";
            break;
        case 1000:
            annText = @"+Umm...you okay?  JK, ultimate calm!";
            break;
            
        default:
            break;
    }
    
    CPTTextLayer *textLayer = [[CPTTextLayer alloc] initWithText:annText style:textStyle];
    CPTLayerAnnotation *instructionsAnnotation = [[CPTLayerAnnotation alloc] initWithAnchorLayer:self.graph.plotAreaFrame.plotArea];
    instructionsAnnotation.contentLayer       = textLayer;
    instructionsAnnotation.rectAnchor         = CPTRectAnchorBottom;
    instructionsAnnotation.contentAnchorPoint = CGPointMake(0.5, 0.0);
    instructionsAnnotation.displacement       = CGPointMake(0.0, 10.0);
    [self.graph.plotAreaFrame.plotArea addAnnotation:instructionsAnnotation];

    
    
    // continue animation graph after a pause
    self.resumeTimer = [NSTimer scheduledTimerWithTimeInterval:INSIGHT_PAUSE_TIME
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
        double currTime = (record.timestamp - record.sessionid - self.dataDelay);
        
        // determine plot color
        CPTMutableLineStyle *dataLineStyle = [CPTLineStyle lineStyle];
        double red = MAX(0.3, (record.breathRate - record.baselineRate) / (20.0 - record.baselineRate));
        double blue = MAX(0.3, (record.baselineRate - record.breathRate) / (record.baselineRate - 5.0));
        double green = MAX(0.3, 0.5 * blue);
        dataLineStyle.lineColor = [CPTColor colorWithComponentRed:red green:green blue:blue alpha:0.7];
        dataLineStyle.lineWidth = 3.0f;
        plot.dataLineStyle = dataLineStyle;
        /* // change area color
        CPTColor *areaColor = [CPTColor colorWithComponentRed:red green:green blue:blue alpha:0.7];
        CPTGradient *areaGradient = [CPTGradient gradientWithBeginningColor:[CPTColor clearColor] endingColor:areaColor];
        areaGradient.angle = -90.0;
        CPTFill *areaGradientFill = [CPTFill fillWithGradient:areaGradient];
        plot.areaFill = areaGradientFill;*/
        
        /*// delete old data points
        if (currTime >= SEC_PER_PLOT) {
            [self.plotData removeObjectAtIndex:0];
            [plot deleteDataInIndexRange:NSMakeRange(0, 1)];
            [baseline deleteDataInIndexRange:NSMakeRange(0, 1)];
        }*/
        
        // shift plotSpace to the right once the plot reaches the right edge of window
        CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
        NSUInteger location = (currTime >= SEC_PER_PLOT ? (currTime - SEC_PER_PLOT) : 0);
        plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromUnsignedInteger(location)
                                                        length:CPTDecimalFromUnsignedInteger(SEC_PER_PLOT)];
        
        // prototyping: pretend we have a list of indices in self.breathrates where
        // insightful data shows up
        NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
        [userInfo setObject:[self.breathrates objectAtIndex:self.currentIndex] forKey:@"record"];
        [userInfo setObject:[NSNumber numberWithInt:self.currentIndex] forKey:@"index"];
        if (self.currentIndex == 200) {
            self.delayTimer = [NSTimer scheduledTimerWithTimeInterval:24.0/FRAME_RATE
                                                               target:self
                                                             selector:@selector(focusOnInsight:)
                                                             userInfo:userInfo
                                                              repeats:NO];
        } else if (self.currentIndex == 310) {
            self.delayTimer = [NSTimer scheduledTimerWithTimeInterval:24.0/FRAME_RATE
                                                               target:self
                                                             selector:@selector(focusOnInsight:)
                                                             userInfo:userInfo
                                                              repeats:NO];
        } else if (self.currentIndex == 450) {
            self.delayTimer = [NSTimer scheduledTimerWithTimeInterval:24.0/FRAME_RATE
                                                               target:self
                                                             selector:@selector(focusOnInsight:)
                                                             userInfo:userInfo
                                                              repeats:NO];
        } else if (self.currentIndex == 550) {
            self.delayTimer = [NSTimer scheduledTimerWithTimeInterval:24.0/FRAME_RATE
                                                               target:self
                                                             selector:@selector(focusOnInsight:)
                                                             userInfo:userInfo
                                                              repeats:NO];
        } else if (self.currentIndex == 750) {
            self.delayTimer = [NSTimer scheduledTimerWithTimeInterval:24.0/FRAME_RATE
                                                               target:self
                                                             selector:@selector(focusOnInsight:)
                                                             userInfo:userInfo
                                                              repeats:NO];
        } else if (self.currentIndex == 1000) {
            self.delayTimer = [NSTimer scheduledTimerWithTimeInterval:24.0/FRAME_RATE
                                                               target:self
                                                             selector:@selector(focusOnInsight:)
                                                             userInfo:userInfo
                                                              repeats:NO];
        }

        self.currentIndex += 1;
        if (self.currentIndex >= self.breathrates.count) {
            [self.dataTimer invalidate];
        // add next data point to plotData
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
    
    // get baseline
    double baseline = ((BreathWearRecord *)[self.breathrates objectAtIndex:0]).baselineRate;
    
    // begin reading through self.breathrates data
    self.currentIndex = 0;
    [self startDataTimer:nil];
    
    // tons of graph set-up //
    //////////////////////////
    self.graph = [[CPTXYGraph alloc] initWithFrame:self.view.bounds];
    [self.graph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    
    CPTGraphHostingView *hostingView = (CPTGraphHostingView *)self.view;
    hostingView.hostedGraph = self.graph;
    self.graph.paddingLeft = 10.0;
    self.graph.paddingTop = 10.0;
    self.graph.paddingRight = 10.0;
    self.graph.paddingBottom = 10.0;
    self.graph.plotAreaFrame.paddingLeft = 50.0;
    self.graph.plotAreaFrame.paddingTop = 35.0;
    self.graph.plotAreaFrame.paddingRight = 20.0;
    self.graph.plotAreaFrame.paddingBottom = 50.0;
    
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0)
                                                    length:CPTDecimalFromFloat(SEC_PER_PLOT)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(baseline - 7.0)
                                                    length:CPTDecimalFromFloat(14.0)];
    plotSpace.allowsUserInteraction = YES;
    
    // text styles
    CPTMutableTextStyle *labelTextStyle = [CPTMutableTextStyle textStyle];
    labelTextStyle.color    = [[CPTColor whiteColor] colorWithAlphaComponent:0.7];
    labelTextStyle.fontSize = 12.0;
    labelTextStyle.fontName = @"Helvetica";
    
    // axes
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    
    CPTMutableLineStyle *axisLineStyle = [CPTLineStyle lineStyle];
    axisLineStyle.lineColor = [[CPTColor blackColor] colorWithAlphaComponent:0.7];
    axisLineStyle.lineWidth = 2.0f;
    CPTMutableLineStyle *majorGridLineStyle = [CPTLineStyle lineStyle];
    majorGridLineStyle.lineWidth = 0.75f;
    majorGridLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.3];
    
    axisSet.xAxis.majorIntervalLength = CPTDecimalFromUnsignedInteger(1);
    axisSet.xAxis.minorTicksPerInterval = 0;
    axisSet.xAxis.majorTickLineStyle = axisLineStyle;
    axisSet.xAxis.minorTickLineStyle = axisLineStyle;
    axisSet.xAxis.axisLineStyle = axisLineStyle;
    axisSet.xAxis.minorTickLength = 5.0f;
    axisSet.xAxis.majorTickLength = 7.0f;
    axisSet.xAxis.title = @"Time (sec since session start)";
    axisSet.xAxis.titleTextStyle = labelTextStyle;
    axisSet.xAxis.titleOffset = 25.0;
    axisSet.xAxis.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    axisSet.xAxis.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    // add positive arrow to xAxis
    CPTLineCap *lineCap = [CPTLineCap sweptArrowPlotLineCap];
    lineCap.size = CGSizeMake(15.0, 15.0);
    lineCap.lineStyle = axisLineStyle;
    lineCap.fill = [CPTFill fillWithColor:lineCap.lineStyle.lineColor];
    axisSet.xAxis.axisLineCapMax = lineCap;
    
    axisSet.yAxis.majorIntervalLength = CPTDecimalFromUnsignedInteger(1);
    axisSet.yAxis.minorTicksPerInterval = 0;
    axisSet.yAxis.majorTickLineStyle = axisLineStyle;
    axisSet.yAxis.minorTickLineStyle = axisLineStyle;
    axisSet.yAxis.axisLineStyle = axisLineStyle;
    axisSet.yAxis.majorGridLineStyle = majorGridLineStyle;
    axisSet.yAxis.minorTickLength = 5.0f;
    axisSet.yAxis.majorTickLength = 7.0f;
    axisSet.yAxis.labelingPolicy = CPTAxisLabelingPolicyNone;
    // add custom labeling to yAxis
    NSSet *majorTickLocations = [NSSet setWithObjects:
                                 [NSDecimalNumber numberWithDouble:baseline - 5.0],
                                 [NSDecimalNumber numberWithDouble:baseline],
                                 [NSDecimalNumber numberWithDouble:baseline + 5.0],
                                 nil];
    axisSet.yAxis.majorTickLocations = majorTickLocations;
    NSMutableSet *newAxisLabels = [NSMutableSet set];
    CPTAxisLabel *newLabel2 = [[CPTAxisLabel alloc] initWithText:@"Calm" textStyle:axisSet.yAxis.labelTextStyle];
    newLabel2.tickLocation = CPTDecimalFromDouble(baseline - 5.0);
    newLabel2.offset = 2.0;
    CPTAxisLabel *newLabel3 = [[CPTAxisLabel alloc] initWithText:@"Zen" textStyle:axisSet.yAxis.labelTextStyle];
    newLabel3.tickLocation = CPTDecimalFromDouble(baseline);
    newLabel3.offset = 2.0;
    CPTAxisLabel *newLabel4 = [[CPTAxisLabel alloc] initWithText:@"Stress" textStyle:axisSet.yAxis.labelTextStyle];
    newLabel4.tickLocation = CPTDecimalFromDouble(baseline + 5.0);
    newLabel4.offset = 2.0;
    [newAxisLabels addObject:newLabel2];
    [newAxisLabels addObject:newLabel3];
    [newAxisLabels addObject:newLabel4];
    axisSet.yAxis.axisLabels = newAxisLabels;
    // prevents yAxis from disappearing when animating forward through graph
    axisSet.yAxis.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    
    // the plots //
    ///////////////
    CPTScatterPlot *dataPlot = [[CPTScatterPlot alloc] init];
    dataPlot.interpolation = CPTScatterPlotInterpolationCurved;
    dataPlot.identifier = kDataPlotID;
    CPTMutableLineStyle *dataLineStyle1 = [CPTLineStyle lineStyle];
    dataLineStyle1.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.7];
    dataLineStyle1.lineWidth = 3.0f;
    dataPlot.dataLineStyle = dataLineStyle1;
    dataPlot.dataSource = self;
    [self.graph addPlot:dataPlot];
    // add area gradient below and above data plot
    CPTColor *areaColor = [CPTColor colorWithComponentRed:0.2 green:0.3 blue:0.6 alpha:0.7];
    CPTGradient *areaGradient = [CPTGradient gradientWithBeginningColor:[CPTColor clearColor] endingColor:areaColor];
    areaGradient.angle = -90.0;
    CPTFill *areaGradientFill = [CPTFill fillWithGradient:areaGradient];
    dataPlot.areaFill      = areaGradientFill;
    dataPlot.areaBaseValue = CPTDecimalFromDouble(baseline);
    
    CPTScatterPlot *baselinePlot = [[CPTScatterPlot alloc] init];
    baselinePlot.identifier = kBaselinePlotID;
    CPTMutableLineStyle *dataLineStyle2 = [CPTLineStyle lineStyle];
    dataLineStyle2.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.5];
    dataLineStyle2.lineWidth = 3.0f;
    baselinePlot.dataLineStyle = dataLineStyle2;
    baselinePlot.dataSource = self;
    [self.graph addPlot:baselinePlot];
    
    // add a legend
    self.graph.legend                    = [CPTLegend legendWithGraph:self.graph];
    self.graph.legend.textStyle          = axisSet.xAxis.titleTextStyle;
    self.graph.legend.fill               = [CPTFill fillWithColor:[CPTColor darkGrayColor]];
    self.graph.legend.borderLineStyle    = axisSet.xAxis.axisLineStyle;
    self.graph.legend.cornerRadius       = 5.0;
    self.graph.legend.swatchSize         = CGSizeMake(25.0, 25.0);
    self.graph.legend.swatchCornerRadius = 5.0;
    self.graph.legendAnchor              = CPTRectAnchorTop;
    self.graph.legendDisplacement        = CGPointMake(0.0, -15.0);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
