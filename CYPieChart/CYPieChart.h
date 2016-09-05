//
//  CYPieChart.h
//  TrackDown
//
//  Created by Gocy on 16/8/12.
//  Copyright © 2016年 Gocy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TitleView.h"

@class PieChartDataObject;
@class CYPieChart;


typedef NS_ENUM(NSUInteger ,TitleLayout){
    TitleLayout_Inside,
    TitleLayout_Bottom,
    TitleLayout_Right
};

@protocol CYPieChartDelegate <NSObject>

/**
 *  Tells the delegate object that a pie has been selected.
 *  @Note This delegate method will NOT be called if the current touch event deselects current pie;
 *
 *  @param pieChart The CYPieChart object
 *  @param index    Index of the selected pie
 */
-(void)pieChart:(CYPieChart *)pieChart didSelectPieAtIndex:(NSInteger)index;

@end

typedef void(^TitleViewAnimationBlock)(TitleView *titleView,BOOL showing);

IB_DESIGNABLE
@interface CYPieChart : UIView

@property (nonatomic ,strong) NSArray <__kindof PieChartDataObject *> *objects;
@property (nonatomic ,strong) NSArray <UIColor *> *colors;

/**
 *  Specify the distance that a pie will move when it's selected , default is 12 points;
 */
@property (nonatomic) CGFloat moveRadius;
/**
 *  Specify the scale that a pie will expand/shrink when it's selected , default is 1.0f;
 */
@property (nonatomic) CGFloat moveScale;
/**
   This value should be set within 0.0 ~ 1.0 , where 0 means each title label will be placed at the center of the pie chart,
   and 1 means each title label will be placed at the end of its corresponding pie.
 
   @note
    This value only works when titleLayout is set to TitleLayout_Inside.
 */
@property (nonatomic) CGFloat titlePosition;

/**
 *  Assign this value to make the pie empty-centered
 */
@property (nonatomic) IBInspectable CGFloat innerRadius;

/**
 *  Position of the titles ,the default value is TitlePosition_Inside ,assigining this property to change the layout position of title labels.
 */
@property (nonatomic) TitleLayout titleLayout;

@property (nonatomic) IBInspectable CGFloat sliceBorderWidth;
@property (nonatomic) IBInspectable UIColor *sliceBorderColor;

@property (nonatomic) TitleViewAnimationBlock titleViewAnimationBlock;

@property (nonatomic ,weak) id <CYPieChartDelegate> delegate;

-(void)deselectCurrentPie;

-(void)updateAppearance;

-(void)goNextWithClockwise:(BOOL)clockwise;

-(CGSize)sizeForTitleViews;

@end
