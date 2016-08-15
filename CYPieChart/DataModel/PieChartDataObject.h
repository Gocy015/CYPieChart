//
//  PieChartDataObject.h
//  TrackDown
//
//  Created by Gocy on 16/8/12.
//  Copyright © 2016年 Gocy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PieChartDataObject : NSObject

@property (nonatomic) CGFloat value;
@property (nonatomic ,copy) NSString *title;


-(instancetype)initWithTitle:(NSString *)title value:(CGFloat)value;

@end
