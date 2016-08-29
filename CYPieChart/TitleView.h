//
//  TitleView.h
//  CYPieChart-Master
//
//  Created by Gocy on 16/8/29.
//  Copyright © 2016年 Gocy. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TitleView;

@protocol TitleViewEventDelegate <NSObject>

-(void)titleViewDidTap:(TitleView *)titleView;

@end

@interface TitleView : UIView

@property (nonatomic ,strong) UIColor *rectColor;
@property (nonatomic ,copy) NSString *title;

@property (nonatomic ,weak) id <TitleViewEventDelegate> delegate;

@end
