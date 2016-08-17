//
//  HighlightPie.h
//  TrackDown
//
//  Created by Gocy on 16/8/12.
//  Copyright © 2016年 Gocy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HighlightPie : UIView

@property (nonatomic ,strong) UIBezierPath *path;
@property (nonatomic ,strong) UIColor *fillColor;

@property (nonatomic ,strong) UIColor *borderColor;
@property (nonatomic) CGFloat borderWidth;

@end
