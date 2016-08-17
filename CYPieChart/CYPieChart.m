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

@interface CYPieChart (){
    NSInteger _tapIndex;
    NSInteger _lastIndex;
    double _sum;
    BOOL _isAnimating;
}


@property (nonatomic ,strong) NSMutableArray *paths;
@property (nonatomic ,strong) NSMutableArray *startAngles;
@property (nonatomic ,strong) NSMutableArray *titleLabels;
@property (nonatomic ,strong) NSMutableArray *fillColors;
@property (nonatomic ,weak) HighlightPie *showPie;
@property (nonatomic ,weak) HighlightPie *hidePie;

@end

static CGFloat kAnimationDuration = 0.22f;

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
}


-(void)dealloc{
    NSLog(@"CYPieChart dealloc");
    [self.paths removeAllObjects];
    for (UIView *v in self.titleLabels) {
        [v removeFromSuperview];
    }
    [self.titleLabels removeAllObjects];
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
    CGFloat radius = self.bounds.size.width / 2 - _sliceBorderWidth;
    
    
    UIBezierPath *shadow = [UIBezierPath new];
    
    self.fillColors = [NSMutableArray arrayWithObjects:[UIColor orangeColor],[UIColor blueColor],[UIColor blackColor],nil];
    
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
        
        [self.fillColors[i] setFill];
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
    [self.paths removeAllObjects];
    
    if (self.objects && self.fillColors) {
        while (self.fillColors.count < self.objects.count) {
            [self.fillColors addObject:[UIColor darkGrayColor]];
        }
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    
    
    CGPoint center = CGPointMake(self.bounds.size.width /2, self.bounds.size.height/2);
    CGFloat radius = self.bounds.size.width / 2 - _sliceBorderWidth;
    
    
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
            
            [self.fillColors[i] setFill];
            
            
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
        
        self.showPie.fillColor = self.fillColors[_tapIndex];
        self.showPie.path = self.paths[_tapIndex];
        self.showPie.borderWidth = self.sliceBorderWidth;
        self.showPie.borderColor = self.sliceBorderColor;
        
        [self.showPie setNeedsDisplay];
        self.showPie.hidden = NO;
        
        CGFloat range = [self angleForObjectAtIndex:_tapIndex];
        CGFloat start = [self.startAngles[_tapIndex] doubleValue];
        
        CGFloat angle = start + range/2.0;
        
        CGAffineTransform trans;
        if ([self.fillColors count] > 1) {
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
    [self setupTitleLabels];

}

-(void)updateAppearance{
    [self reset];
    [self setNeedsDisplay];
    [self setupTitleLabels];
}


-(void)deselectCurrentPie{
    if (_tapIndex != -1) {
        _tapIndex = -1;
        [self switchSelectedPie];
    }
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

-(void)setupTitleLabels{
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
    
    
    for (NSUInteger i = 0; i < self.objects.count; ++i) {
        
        UILabel *label = self.titleLabels[i];
        
        if (_tapIndex == i) {
            
            CGFloat range = [self angleForObjectAtIndex:i];
            CGFloat start = [self.startAngles[i] doubleValue];
            
            CGFloat angle = start + range/2.0 ;
            
            CGAffineTransform trans = CGAffineTransformMakeTranslation(cos(angle) * self.moveRadius, sin(angle) * self.moveRadius);
            trans = CGAffineTransformScale(trans, self.moveScale, self.moveScale);
            [UIView animateWithDuration:kAnimationDuration animations:^{
                label.transform = trans;
            }];
        }
        else if (_lastIndex != _tapIndex && _lastIndex == i) {
            
            [UIView animateWithDuration:kAnimationDuration animations:^{
                
                label.transform = CGAffineTransformIdentity;
            }];
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
    _colors = colors;
    self.fillColors = [NSMutableArray arrayWithArray:colors];
    
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
