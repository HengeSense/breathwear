//
//  BrythmViewController.m
//  Brythm
//
//  Created by Cassidy Robert Coyote Saenz on 12/4/12.
//  Copyright (c) 2012 Cassidy Robert Coyote Saenz. All rights reserved.
//

#import "BrythmViewController.h"
#import "BreathWearDatabase.h"
#import "BreathWearRecord.h"

#define DEFAULT_SESSION_ID 1328075662

@interface BrythmViewController ()

@property (nonatomic, strong) BreathWearDatabase *db;
@property (nonatomic, weak) NSArray *breathrates;
@property (nonatomic) int sessionid;
@property (nonatomic, weak) CPTXYGraph *graph;

@end


@implementation BrythmViewController

@synthesize db = _db;
@synthesize breathrates = _breathrates;
@synthesize sessionid = _sessionid;
@synthesize graph = _graph;

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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

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

# pragma mark - ViewController Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.db = [BreathWearDatabase getDatabase];
    self.breathrates = [self.db getRecordsForSession:DEFAULT_SESSION_ID];
    
    self.graph = [[CPTXYGraph alloc] initWithFrame:self.view.bounds];
    [self.graph applyTheme:[CPTTheme themeNamed:kCPTSlateTheme]];
    
    CPTGraphHostingView *hostingView = (CPTGraphHostingView *)self.view;
    hostingView.hostedGraph = self.graph;
    self.graph.paddingLeft = 20.0;
    self.graph.paddingTop = 200.0;
    self.graph.paddingRight = 20.0;
    self.graph.paddingBottom = 20.0;

    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-180)
                                                   length:CPTDecimalFromFloat(1200)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-3)
                                                   length:CPTDecimalFromFloat(25)];
    plotSpace.allowsUserInteraction = YES;
    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    
    CPTMutableLineStyle *lineStyle = [CPTLineStyle lineStyle];
    lineStyle.lineColor = [CPTColor blackColor];
    lineStyle.lineWidth = 2.0f;
    
    axisSet.xAxis.majorIntervalLength = CPTDecimalFromUnsignedInteger(5);
    axisSet.xAxis.minorTicksPerInterval = 2;
    axisSet.xAxis.majorTickLineStyle = lineStyle;
    axisSet.xAxis.minorTickLineStyle = lineStyle;
    axisSet.xAxis.axisLineStyle = lineStyle;
    axisSet.xAxis.minorTickLength = 5.0f;
    axisSet.xAxis.majorTickLength = 7.0f;
    axisSet.xAxis.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    
    axisSet.yAxis.majorIntervalLength = CPTDecimalFromUnsignedInteger(5);
    axisSet.yAxis.minorTicksPerInterval = 2;
    axisSet.yAxis.majorTickLineStyle = lineStyle;
    axisSet.yAxis.minorTickLineStyle = lineStyle;
    axisSet.yAxis.axisLineStyle = lineStyle;
    axisSet.yAxis.minorTickLength = 5.0f;
    axisSet.yAxis.majorTickLength = 7.0f;
    axisSet.yAxis.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    
    CPTScatterPlot *plot = [[CPTScatterPlot alloc]
                                    init];
    plot.identifier = @"Main Plot";
    CPTMutableLineStyle *dataLineStyle1 = [CPTLineStyle lineStyle];
    dataLineStyle1.lineColor = [CPTColor blueColor];
    dataLineStyle1.lineWidth = 1.0f;
    plot.dataLineStyle = dataLineStyle1;
    plot.dataSource = self;
    [self.graph addPlot:plot];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
