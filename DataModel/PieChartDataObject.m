//
//  PieChartDataObject.m
//  TrackDown
//
//  Created by Gocy on 16/8/12.
//  Copyright © 2016年 Gocy. All rights reserved.
//

#import "PieChartDataObject.h"

@implementation PieChartDataObject

-(instancetype)initWithTitle:(NSString *)title value:(CGFloat)value{
    if (self = [super init]) {
        _title = title;
        _value = value;
    }
    return self;
}

@end
