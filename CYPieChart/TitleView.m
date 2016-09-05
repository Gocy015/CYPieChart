//
//  TitleView.m
//  CYPieChart-Master
//
//  Created by Gocy on 16/8/29.
//  Copyright © 2016年 Gocy. All rights reserved.
//

#import "TitleView.h"

@interface TitleView ()

@property (nonatomic ,weak) CALayer *rectLayer;
@property (nonatomic ,weak) CATextLayer *textLayer;

@end

@implementation TitleView

#pragma mark - Life Cycle

-(instancetype)init{
    if (self = [super init]) {
        [self initLayers];
        [self initGestures];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self initLayers];
        [self initGestures];
        [self layoutLayers];
    }
    return self;
}




#pragma mark - Helpers

-(void)initLayers{
    
    
    CALayer *rectLayer = [CALayer new];
    rectLayer.borderWidth = 1;
    rectLayer.borderColor = [UIColor blackColor].CGColor;
    [self.layer addSublayer:rectLayer];
    _rectLayer = rectLayer;
    
    CATextLayer *textLayer = [CATextLayer new];
    [textLayer setFont:(__bridge CFTypeRef _Nullable)([UIFont systemFontOfSize:12 weight:UIFontWeightLight])];
    textLayer.foregroundColor = self.titleColor ? self.titleColor.CGColor : [UIColor blackColor].CGColor;
    textLayer.contentsScale = [UIScreen mainScreen].scale;
    textLayer.wrapped = YES;
    [self.layer addSublayer:textLayer];
    _textLayer = textLayer;
    
    
    
}

-(void)layoutLayers{
    CGFloat len = MIN(self.bounds.size.width, self.bounds.size.height) * 3 / 4;
    CGFloat padding = len; // temp
    _rectLayer.frame = CGRectMake(padding, (self.bounds.size.height - len) / 2, len, len);
    
    CGFloat distance = 2;
    CGFloat left = CGRectGetMaxX(_rectLayer.frame) + distance;
    _textLayer.frame = CGRectMake(left , 0, self.bounds.size.width - left - padding, self.bounds.size.height);
    [_textLayer setFontSize:self.bounds.size.height - 1];
}


-(void)initGestures{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc ] initWithTarget:self action:@selector(didTap:)];
    [self addGestureRecognizer:tap];
}

#pragma mark - Setters

-(void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    
    [self layoutLayers];
}

-(void)setTitle:(NSString *)title{
    if ([_title isEqualToString:title]) {
        return ;
    }
    _title = title;
    [_textLayer setString:title];
}

-(void)setRectColor:(UIColor *)rectColor{
    _rectColor = rectColor;
    _rectLayer.backgroundColor = rectColor.CGColor;
    
}

-(void)setTitleColor:(UIColor *)titleColor{
    _titleColor = titleColor;
    
    if (_textLayer) {
        _textLayer.foregroundColor = titleColor.CGColor;
    }
}


#pragma mark - Actions

-(void)didTap:(UITapGestureRecognizer *)tap{
    if ([self.delegate respondsToSelector:@selector(titleViewDidTap:)]) {
        [self.delegate titleViewDidTap:self];
    }
}


@end
