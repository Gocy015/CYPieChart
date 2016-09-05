//
//  CYPieChart.m
//  TrackDown
//
//  Created by Gocy on 16/8/12.
//  Copyright © 2016年 Gocy. All rights reserved.
//

#import "CYPieChart.h"
#import "PieChartDataObject.h"
#import "HighlightPie.h"
#import "TitleView.h"

@interface CYPieChart () <TitleViewEventDelegate> {
    NSInteger _tapIndex;
    NSInteger _lastIndex;
    double _sum;
    BOOL _isAnimating;
}


@property (nonatomic ,strong) NSMutableArray *paths;
@property (nonatomic ,strong) NSMutableArray *startAngles;
@property (nonatomic ,strong) NSMutableArray *titleLabels;
@property (nonatomic ,strong) NSMutableArray *titleViews;

@property (nonatomic ,weak) HighlightPie *showPie;
@property (nonatomic ,weak) HighlightPie *hidePie;

@end

static const CGFloat kAnimationDuration = 0.22f;

static const CGFloat kTitleViewWidth = CGFLOAT_MAX;
static const CGFloat kTitleViewHeight = 16;
static const CGFloat kTitleViewHorizontalPadding = 6;
static const CGFloat kTitleViewVerticalPadding = 4;
static const CGFloat kTitleViewInset =  6;

@implementation CYPieChart

#pragma mark - Life Cycle

-(void)awakeFromNib{
    [self initialize];
}

-(instancetype)init{
    if (self = [super init]) {
        [self initialize];
    }
    
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    
    return self;
}




-(void)initialize{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    [self addGestureRecognizer:tap];
    
    self.layer.shadowOpacity = 0.6;
    self.layer.shadowOffset = CGSizeMake(0, 6);
    self.backgroundColor = [UIColor clearColor];
    
    _tapIndex = -1;
    _lastIndex = -1;
    _sum = 0.0;
    _isAnimating = NO;
    
    _moveRadius = 12;
    _moveScale = 1;
    _titlePosition = 0.6;
    
    _innerRadius = 0;
    _sliceBorderWidth = 0;
    
    _titleLayout = TitleLayout_Inside;
}


-(void)dealloc{
    NSLog(@"CYPieChart dealloc");
    [self.paths removeAllObjects];
    for (UIView *v in self.titleLabels) {
        [v removeFromSuperview];
    }
    [self.titleLabels removeAllObjects];
    
    for (TitleView *view in self.titleViews) {
        [view removeFromSuperview];
    }
    [self.titleViews removeAllObjects];
}

#pragma mark - Drawing & Drawing Helpers
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    
//    NSLog(@"Draw Rect");
#if TARGET_INTERFACE_BUILDER // appearance in IB
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    
    
    CGPoint center = CGPointMake(self.bounds.size.width /2, self.bounds.size.height/2);
    CGFloat radius = MIN(self.bounds.size.width, self.bounds.size.height) / 2 - _sliceBorderWidth;
    
    
    UIBezierPath *shadow = [UIBezierPath new];
    
    self.colors = @[[UIColor orangeColor],[UIColor blueColor],[UIColor blackColor]];
    
    CGContextSaveGState(context);
    
    CGFloat lastAngle = M_PI;
    for (int i = 0; i < 3; ++i) {
        CGFloat angle = M_PI * 2 / 3;
        CGFloat startAngle = lastAngle;
        CGFloat endAngle = startAngle + angle;
        lastAngle = endAngle;
        
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
        if(_innerRadius > 0 && _innerRadius < radius - 1){
            [path addArcWithCenter:center radius:_innerRadius startAngle:endAngle endAngle:startAngle clockwise:NO];
            [path closePath];
        }
        else{
            [path addLineToPoint:center];
            [path closePath];
        }
        
        [self.colors[i] setFill];
        [shadow appendPath:path];
        
        [path fill];
        
        
        if (_sliceBorderColor && _sliceBorderWidth > 0) {
            [_sliceBorderColor setStroke];
            shadow.lineWidth = _sliceBorderWidth;
            [shadow stroke];
        }

        [self.paths addObject:path];
        lastAngle = endAngle;
    }
    
    CGContextRestoreGState(context);
    
    
    self.layer.shadowPath = shadow.CGPath;
    
#else
    
    NSAssert(self.colors.count != 0, @"Color Array should have at least one element !");
    
    [self.paths removeAllObjects];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGSize titleSize = [self sizeForTitleViews];
    CGFloat hspace = 0;
    CGFloat vspace = 0;
    if (self.titleLayout == TitleLayout_Bottom) {
        vspace = titleSize.height;
    }else if(self.titleLayout == TitleLayout_Right){
        hspace = titleSize.width;
    }
    
    CGFloat length = MIN(self.bounds.size.width - hspace, self.bounds.size.height - vspace);
    CGFloat radius = length / 2 - _sliceBorderWidth;
    
    CGPoint center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    if (self.titleLayout == TitleLayout_Bottom) {
        center.y = (self.bounds.size.height - titleSize.height) / 2;
    }else if(self.titleLayout == TitleLayout_Right){
        center.x = (self.bounds.size.width - titleSize.width) / 2;
    }
    
    
    
    UIBezierPath *shadow = [UIBezierPath new];
    CGContextSaveGState(context);
    
    CGFloat lastAngle = M_PI;
    for (int i = 0; i < self.objects.count; ++i) {
        CGFloat angle = [self angleForObjectAtIndex:i];
        CGFloat startAngle = [self.startAngles[i] doubleValue];
        CGFloat endAngle = startAngle + angle;
        
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
        if(_innerRadius > 0 && _innerRadius < radius - 1){
            [path addArcWithCenter:center radius:_innerRadius startAngle:endAngle endAngle:startAngle clockwise:NO];
            [path closePath];
        }
        else{
            [path addLineToPoint:center];
            [path closePath];
        }
        
        if (_tapIndex == i || _lastIndex == i) {
            
            [[UIColor clearColor] setFill];
            
        }else{
            
            [self.colors[i % self.colors.count] setFill];
            
            [shadow appendPath:path];
            
        }
        [path fill];
        
        if (_sliceBorderColor && _sliceBorderWidth > 0) {
            [_sliceBorderColor setStroke];
            shadow.lineWidth = _sliceBorderWidth;
            [shadow stroke];
        }

        
        [self.paths addObject:path];
        lastAngle = endAngle;
    }
    
    CGContextRestoreGState(context);
    
    
    self.layer.shadowPath = shadow.CGPath;
#endif
}

#pragma mark - Instance Method
-(void)goNextWithClockwise:(BOOL)clockwise{
    if (_tapIndex < 0 || _isAnimating) {
        return;
    }
    if (clockwise) {
        _tapIndex = (_tapIndex + 1) % self.objects.count;
    }else{
        _tapIndex = (self.objects.count + _tapIndex - 1) % self.objects.count;
    }
    
    [self switchSelectedPie];
}

-(CGSize)sizeForTitleViews{
    CGFloat width = 0;
    if (self.titleLayout == TitleLayout_Bottom) { //place at bottom , width no more than entire width
        width = MIN(2 * kTitleViewWidth + kTitleViewHorizontalPadding + 2 *kTitleViewInset,self.bounds.size.width);
    }else{ // place at right , width no more than half the entire width.
        width = MIN(2 * kTitleViewWidth + kTitleViewHorizontalPadding + 2 *kTitleViewInset ,self.bounds.size.width / 2);
    }

    NSUInteger lines = ceil(self.objects.count / 2.0);
    
    CGFloat height = kTitleViewHeight * lines + kTitleViewHorizontalPadding * (lines - 1);
    
    return CGSizeMake(width, height + 2 * kTitleViewInset);
}

#pragma mark - Actions
-(void)didTap:(UITapGestureRecognizer *)tap{
    if (_isAnimating) {
        return ;
    }
    CGPoint p = [tap locationInView:self];
    BOOL found = NO;
    for (UIBezierPath *path in self.paths) {
        if ([path containsPoint:p]) {
            found = YES;
            NSInteger idx = [self.paths indexOfObject:path];
            if (idx == _tapIndex) {
                _tapIndex = -1;
            }else{
                _tapIndex = idx;
            }
            
            break;
        }
    }
    if (!found) {
        _tapIndex = -1;
    }
    
    [self switchSelectedPie];
}

-(void)switchSelectedPie{
    
    NSInteger temp = _tapIndex;
    
    self.hidePie.hidden = YES;
    self.hidePie.path = nil;
    self.hidePie.fillColor = nil;
    self.hidePie.borderWidth = 0;
    self.hidePie.borderColor = nil;
    
    if (_lastIndex >= 0) {
        self.hidePie.fillColor = self.showPie.fillColor;
        self.hidePie.path = self.showPie.path;
        self.hidePie.borderWidth = self.sliceBorderWidth;
        self.hidePie.borderColor = self.sliceBorderColor;
        
        self.hidePie.transform = self.showPie.transform;
        [self.hidePie setNeedsDisplay];
        self.hidePie.hidden = NO;
        _isAnimating = YES;
        //        UILabel *label = self.titleLabels[_lastIndex];
        [UIView animateWithDuration:kAnimationDuration animations:^{
            self.hidePie.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            _lastIndex = temp;
            _isAnimating = NO;
            self.hidePie.hidden = YES;
            [self setNeedsDisplay];
        }];
    }else{
        _lastIndex = temp;
    }
    
    
    
    self.showPie.hidden = YES;
    self.showPie.path = nil;
    self.showPie.fillColor = nil;
    self.showPie.borderWidth = 0;
    self.showPie.borderColor = nil;
    self.showPie.transform = CGAffineTransformIdentity;
    
    if (_tapIndex >= 0) {
        
        [self setNeedsDisplay];
        
        self.showPie.fillColor = self.colors[_tapIndex % self.colors.count];
        self.showPie.path = self.paths[_tapIndex];
        self.showPie.borderWidth = self.sliceBorderWidth;
        self.showPie.borderColor = self.sliceBorderColor;
        
        [self.showPie setNeedsDisplay];
        self.showPie.hidden = NO;
        
        CGFloat range = [self angleForObjectAtIndex:_tapIndex];
        CGFloat start = [self.startAngles[_tapIndex] doubleValue];
        
        CGFloat angle = start + range/2.0;
        
        CGAffineTransform trans;
        if ([self.colors count] > 1) {
            trans = CGAffineTransformMakeTranslation(cos(angle) * self.moveRadius, sin(angle) * self.moveRadius);
            trans = CGAffineTransformScale(trans, self.moveScale, self.moveScale);
        }else{
            trans = CGAffineTransformMakeScale(self.moveScale, self.moveScale);
        }
        [UIView animateWithDuration:kAnimationDuration animations:^{
            self.showPie.transform = trans;
        }];
        if (self.delegate && [self.delegate respondsToSelector:@selector(pieChart:didSelectPieAtIndex:)]) {
            [self.delegate pieChart:self didSelectPieAtIndex:_tapIndex];
        }
    }
    [self setupTitles];

}

-(void)updateAppearance{
    [self reset];
    [self setNeedsDisplay];
    [self setupTitles];
}


-(void)deselectCurrentPie{
    if (_tapIndex != -1) {
        _tapIndex = -1;
        [self switchSelectedPie];
    }
}

#pragma mark - TitleViewEventDelegate
-(void)titleViewDidTap:(TitleView *)titleView{
    if (_isAnimating) {
        return ;
    }
    NSUInteger index = [self.titleViews indexOfObject:titleView];
    if (index == _tapIndex) {
        _tapIndex = -1;
    }
    else{
        _tapIndex = index;
    }
    [self switchSelectedPie];
}


#pragma mark - Helpers

-(void)reset{
    
    self.showPie.hidden = YES;
    self.hidePie.hidden = YES;
    
    _tapIndex = _lastIndex = -1;
}

-(CGFloat)angleForObjectAtIndex:(NSUInteger)idx{
    if (_sum <= 0) {
        return 0;
    }
    CGFloat angle = M_PI * 2 * (self.objects[idx].value) / _sum;
    return angle;
}


-(void)calculateStartAngles{
    [self.startAngles removeAllObjects];
    CGFloat lastAngle = M_PI;
    for (int i = 0; i < self.objects.count; ++i) {
        CGFloat angle = [self angleForObjectAtIndex:i];
        CGFloat startAngle = lastAngle;
        lastAngle = startAngle + angle;
        
        [self.startAngles addObject:@(startAngle)];
    }
}

-(void)setupTitles{
    if (self.titleLayout == TitleLayout_Inside) {
        if (self.titleLabels.count != self.objects.count) {
            for (UIView *v in self.titleLabels) {
                [v removeFromSuperview];
            }
            [self.titleLabels removeAllObjects];
            for (NSUInteger i = 0; i < self.objects.count; ++i) {
                
                UILabel *label = [UILabel new];
                label.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
                label.textColor = [UIColor whiteColor];
                label.text = self.objects[i].title;
                label.shadowOffset = CGSizeMake(0, 4);
                
                [label sizeToFit];
                
                [self addSubview:label];
                [self.titleLabels addObject:label];
                
                CGFloat range = [self angleForObjectAtIndex:i];
                CGFloat start = [self.startAngles[i] doubleValue];
                
                CGFloat radius = self.bounds.size.width / 2;
                CGFloat angle = start + range/2.0;
                CGPoint offset = CGPointMake(cos(angle) * radius * self.titlePosition, sin(angle) * radius * self.titlePosition);
                CGPoint center = CGPointMake(self.bounds.size.width / 2 , self.bounds.size.height / 2);
                
                label.center = CGPointMake(center.x + offset.x, center.y + offset.y);
            }
        }
        
        
        if (_tapIndex >= 0 && _tapIndex < self.titleLabels.count){
            
            UILabel *label = self.titleLabels[_tapIndex];
            CGFloat range = [self angleForObjectAtIndex:_tapIndex];
            CGFloat start = [self.startAngles[_tapIndex] doubleValue];
            
            CGFloat angle = start + range/2.0 ;
            
            CGAffineTransform trans = CGAffineTransformMakeTranslation(cos(angle) * self.moveRadius, sin(angle) * self.moveRadius);
            trans = CGAffineTransformScale(trans, self.moveScale, self.moveScale);
            [UIView animateWithDuration:kAnimationDuration animations:^{
                label.transform = trans;
            }];

        }
        if (_lastIndex != _tapIndex && _lastIndex >=0 && _lastIndex < self.titleLabels.count) {
            
            UILabel *label = self.titleLabels[_lastIndex];
            
            [UIView animateWithDuration:kAnimationDuration animations:^{
                
                label.transform = CGAffineTransformIdentity;
            }];
        }
//        
//        for (NSUInteger i = 0; i < self.objects.count; ++i) {
//            
//            UILabel *label = self.titleLabels[i];
//            
//            if (_tapIndex == i) {
//                
//                CGFloat range = [self angleForObjectAtIndex:i];
//                CGFloat start = [self.startAngles[i] doubleValue];
//                
//                CGFloat angle = start + range/2.0 ;
//                
//                CGAffineTransform trans = CGAffineTransformMakeTranslation(cos(angle) * self.moveRadius, sin(angle) * self.moveRadius);
//                trans = CGAffineTransformScale(trans, self.moveScale, self.moveScale);
//                [UIView animateWithDuration:kAnimationDuration animations:^{
//                    label.transform = trans;
//                }];
//            }
//            else if (_lastIndex != _tapIndex && _lastIndex == i) {
//                
//                [UIView animateWithDuration:kAnimationDuration animations:^{
//                    
//                    label.transform = CGAffineTransformIdentity;
//                }];
//            }
//        }

    }else{
        // title View
        if (self.titleViews.count != self.objects.count) {
            for (TitleView *view in self.titleViews) {
                [view removeFromSuperview];
            }
            [self.titleViews removeAllObjects];
            
            //calculate frame.
            CGSize titleSize = [self sizeForTitleViews];
            CGPoint start = CGPointZero;
            if (self.titleLayout == TitleLayout_Bottom) {
                start = CGPointMake((self.bounds.size.width - titleSize.width) / 2 + kTitleViewInset, self.bounds.size.height - titleSize.height + kTitleViewInset);
            }else if (self.titleLayout == TitleLayout_Right){
                start = CGPointMake(self.bounds.size.width - titleSize.width + kTitleViewInset, (self.bounds.size.height - titleSize.height) / 2 + kTitleViewInset );
            }
            
            CGFloat width = (titleSize.width - 2*kTitleViewInset - kTitleViewHorizontalPadding) / 2;
            CGFloat height = kTitleViewHeight;
            CGPoint origin = CGPointZero;
            
            for (NSUInteger i = 0; i < self.objects.count; ++i) {
                TitleView *titleView = [TitleView new];
                titleView.delegate = self;
                titleView.rectColor = self.colors[i % self.colors.count];
                titleView.title = self.objects[i].title;
                
                [self addSubview:titleView];
                [self.titleViews addObject:titleView];
                
                origin = CGPointMake(start.x + (i % 2) * (width + kTitleViewHorizontalPadding), start.y + (i / 2) * (height + kTitleViewVerticalPadding));
                titleView.transform = CGAffineTransformIdentity;
                titleView.frame = CGRectMake(origin.x, origin.y, width, height);
            }
            
        }
        
        if (_tapIndex >= 0 && _tapIndex < self.titleViews.count){
            
            TitleView *titleView = self.titleViews[_tapIndex];
            
            if(self.titleViewAnimationBlock){
                [UIView animateWithDuration:kAnimationDuration animations:^{
                    
                    self.titleViewAnimationBlock(titleView,YES);
                }];
            }else{
                CGAffineTransform trans = CGAffineTransformMakeScale(1.2, 1.2);
                trans = CGAffineTransformTranslate(trans, 0.1*titleView.bounds.size.width, 0);
                [UIView animateWithDuration:kAnimationDuration animations:^{
                    
                    titleView.transform = trans;
                }];
            }
            
        }
        if (_lastIndex != _tapIndex && _lastIndex >=0 && _lastIndex < self.titleViews.count) {
            
            TitleView *titleView = self.titleViews[_lastIndex];
            if(self.titleViewAnimationBlock){
                [UIView animateWithDuration:kAnimationDuration animations:^{
                    
                    self.titleViewAnimationBlock(titleView,NO);
                }];
                
            }else{
                [UIView animateWithDuration:kAnimationDuration animations:^{
                    
                    titleView.transform = CGAffineTransformIdentity;
                }];
                
            }
        }
        
    }
    
}


#pragma mark - Setters & Getters


-(NSMutableArray *)paths{
    if (!_paths) {
        _paths = [NSMutableArray new];
    }
    return _paths;
}

-(NSMutableArray *)startAngles{
    if (!_startAngles) {
        _startAngles = [NSMutableArray new];
    }
    return _startAngles;
}

-(NSMutableArray *)titleLabels{
    if (!_titleLabels) {
        _titleLabels = [NSMutableArray new];
    }
    return _titleLabels;
}
-(NSMutableArray *)titleViews{
    if (!_titleViews) {
        _titleViews = [NSMutableArray new];
    }
    return _titleViews;
}



-(HighlightPie *)showPie{
    if (!_showPie) {
        HighlightPie *p = [[HighlightPie alloc] initWithFrame:self.bounds];
        [self addSubview:p];
        p.hidden = YES;
        
        _showPie = p;
    }
    [self sendSubviewToBack:_showPie];
    return _showPie;
}


-(HighlightPie *)hidePie{
    if (!_hidePie) {
        HighlightPie *p = [[HighlightPie alloc] initWithFrame:self.bounds];
        [self addSubview:p];
        p.hidden = YES;
        
        _hidePie = p;
    }
    [self sendSubviewToBack:_hidePie];
    return _hidePie;
}

-(void)setObjects:(NSArray<__kindof PieChartDataObject *> *)objects{
    _objects = objects;
    _sum = 0.0f;
    for (PieChartDataObject *obj in objects) {
        _sum += obj.value;
    }
    [self calculateStartAngles];
}

-(void)setColors:(NSArray<UIColor *> *)colors{
    _colors = colors;\
    
}

-(void)setInnerRadius:(CGFloat)innerRadius{
    if (innerRadius < 0) {
        _innerRadius = 0;
    }else{
        _innerRadius = innerRadius;
    }
    [self setNeedsDisplay];
}

-(void)setSliceBorderColor:(UIColor *)sliceBorderColor{
    _sliceBorderColor = sliceBorderColor;
    
    [self setNeedsDisplay];
}

-(void)setSliceBorderWidth:(CGFloat)sliceBorderWidth{
    if (sliceBorderWidth < 0) {
        _sliceBorderWidth = 0;
    }else{
        _sliceBorderWidth = sliceBorderWidth;
    }
    [self setNeedsDisplay];
}
@end
