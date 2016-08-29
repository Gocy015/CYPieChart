//
//  ViewController.m
//  CYPieChart-Master
//
//  Created by Gocy on 16/8/15.
//  Copyright © 2016年 Gocy. All rights reserved.
//

#import "ViewController.h"
#import "CYPieChart.h"
#import "PieChartDataObject.h"

#define RANDOM_COLOR() \
[UIColor colorWithRed:(arc4random() % 255 / 255.0) green:(arc4random() % 255 / 255.0) blue:(arc4random() % 255 / 255.0) alpha:1]

@interface ViewController () <CYPieChartDelegate>

@property (weak, nonatomic) IBOutlet CYPieChart *pieChart;

@end

static const NSUInteger MAX_PARTS = 20;
static const NSUInteger MIN_PARTS = 2;
static const NSInteger leftArrowTag = 21;
static const NSInteger rightArrowTag = 22;

@implementation ViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSArray *obj = [self generateRandomData];
    NSArray *colors = [self generateRandomColorsOfCount:obj.count];
    [self initGestures];
    
    self.pieChart.objects = obj;
    self.pieChart.colors = colors;
    self.pieChart.delegate = self;
//    self.pieChart.innerRadius = 20;
    
    self.pieChart.sliceBorderWidth = 1;
    self.pieChart.sliceBorderColor = [UIColor blackColor];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
//    self.pieChart.titlePosition = 0.9f;
    self.pieChart.titleLayout = TitleLayout_Bottom;
    [self.pieChart updateAppearance];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Actions

- (IBAction)arrowClicked:(UIButton *)sender {
    if (sender.tag == leftArrowTag) {
        [self.pieChart goNextWithClockwise:YES];
    }else if (sender.tag == rightArrowTag){
        [self.pieChart goNextWithClockwise:NO];
    }
}

- (IBAction)regenerate:(id)sender {
    NSArray *obj = [self generateRandomData];
    NSArray *colors = [self generateRandomColorsOfCount:obj.count];
    
    self.pieChart.objects = obj;
    self.pieChart.colors = colors;
    
    [self.pieChart updateAppearance];
}
-(void)didTap:(UITapGestureRecognizer *)tap{
    [self.pieChart deselectCurrentPie];
}


#pragma mark - CYPieChart Delegate

-(void)pieChart:(CYPieChart *)pieChart didSelectPieAtIndex:(NSInteger)index{
    NSLog(@"Pie Chart Selected At Index : %li",index);
}

#pragma mark - Helpers

-(NSArray *)generateRandomData{
    
    NSMutableArray *arr = [NSMutableArray new];
    
    NSUInteger count = MAX(MIN_PARTS, arc4random() % MAX_PARTS + 1);
    for (NSUInteger i = 0; i < count; ++i) {
        PieChartDataObject *obj = [[PieChartDataObject alloc] initWithTitle:[NSString stringWithFormat:@"%lu",i] value:i + 1];
        [arr addObject:obj];
    }
    
    return [NSArray arrayWithArray:arr];
}

-(NSArray *)generateRandomColorsOfCount:(NSInteger)count{
    
    NSMutableArray *arr = [NSMutableArray new];
    
    for (NSUInteger i = 0; i < count; ++i) {
        [arr addObject:RANDOM_COLOR()];
    }
    
    return [NSArray arrayWithArray:arr];
}

-(void)initGestures{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(didTap:)];
    [self.view addGestureRecognizer:tap];
}

@end
