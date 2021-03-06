//
//  PDGesturedTableView.m
//  Proday
//
//  Created by David Román Aguirre on 24/08/13.
//  Copyright (c) 2013 David Román Aguirre. All rights reserved.
//

#import "PDGesturedTableView.h"

#pragma mark Interface Extensions & Private Interfaces

@interface PDGesturedTableViewCellSlidingFraction ()

@property (strong, nonatomic) UIImage * icon;
@property (strong, nonatomic) UIColor * color;
@property (nonatomic) CGFloat activationFraction;

@end

@interface PDGesturedTableViewCellSlidingView : UIView

@property (strong, nonatomic) UIImageView * leftIconImageView;
@property (strong, nonatomic) UIImageView * rightIconImageView;

@end

@interface PDGesturedTableViewCell () {
    NSArray * currentSlidingFractions;
    PDGesturedTableViewCellSlidingFraction * currentSlidingFraction;
    CGFloat originalHorizontalCenter;
}

@property (weak, nonatomic) PDGesturedTableView * gesturedTableView;
@property (strong, nonatomic) PDGesturedTableViewCellSlidingView * slidingView;

@property (strong, nonatomic) NSMutableArray * leftSlidingFractions;
@property (strong, nonatomic) NSMutableArray * rightSlidingFractions;

@end

@interface PDGesturedTableView ()

@property (nonatomic) BOOL updating;

@end

#pragma mark Implementations

@implementation PDGesturedTableViewCellSlidingFraction

+ (id)slidingFractionWithIcon:(UIImage *)icon color:(UIColor *)color activationFraction:(CGFloat)activationFraction {
    PDGesturedTableViewCellSlidingFraction * slidingFraction = [PDGesturedTableViewCellSlidingFraction new];
    
    [slidingFraction setIcon:icon];
    [slidingFraction setColor:color];
    [slidingFraction setActivationFraction:activationFraction];
    
    return slidingFraction;
}

@end

@implementation PDGesturedTableViewCellSlidingView

- (id)init {
    if (self = [super init]) {
        self.leftIconImageView = [UIImageView new];
        self.rightIconImageView = [UIImageView new];
        
        [self.leftIconImageView setContentMode:UIViewContentModeLeft];
        [self.rightIconImageView setContentMode:UIViewContentModeRight];
    }
    
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    CGFloat iconImageViewsMargin = 17;
    CGRect iconImageViewsFrame = CGRectMake(iconImageViewsMargin, 0, self.frame.size.width-iconImageViewsMargin*2, self.frame.size.height);
    
    [self.leftIconImageView setFrame:iconImageViewsFrame];
    [self.rightIconImageView setFrame:iconImageViewsFrame];
    
    [self addSubview:self.leftIconImageView];
    [self addSubview:self.rightIconImageView];
}

- (void)setIcon:(UIImage *)icon {
    [self.leftIconImageView setImage:icon];
    [self.rightIconImageView setImage:icon];
}

- (void)setIconsAlpha:(CGFloat)alpha {
    [self.leftIconImageView setAlpha:alpha];
    [self.rightIconImageView setAlpha:-alpha];
}

@end

@implementation PDGesturedTableViewCell

- (id)initForGesturedTableView:(PDGesturedTableView *)gesturedTableView style:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
        self.gesturedTableView = gesturedTableView;
        self.slidingView = [PDGesturedTableViewCellSlidingView new];
        
        self.leftSlidingFractions = [NSMutableArray new];
        self.rightSlidingFractions = [NSMutableArray new];
        
        UIPanGestureRecognizer * panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(slideCell:)];
        [panGestureRecognizer setDelegate:self];
        [self addGestureRecognizer:panGestureRecognizer];
    }
    
    return self;
}

- (void)addSlidingFraction:(PDGesturedTableViewCellSlidingFraction *)slidingFraction {
    if (slidingFraction.activationFraction > 0) {
        [self.leftSlidingFractions addObject:slidingFraction];
    } else if (slidingFraction.activationFraction < 0) {
        [self.rightSlidingFractions addObject:slidingFraction];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isKindOfClass:NSClassFromString(@"UIPanGestureRecognizer")]) {
        CGFloat horizontalLocation = [(UIPanGestureRecognizer *)gestureRecognizer locationInView:self].x;
        CGPoint translation = [(UIPanGestureRecognizer *)gestureRecognizer translationInView:self];
         
        if (horizontalLocation > self.gesturedTableView.edgeSlidingMargin && horizontalLocation < self.frame.size.width - self.gesturedTableView.edgeSlidingMargin && fabsf(translation.x) >= fabsf(translation.y) && self.gesturedTableView.enabled) {
            return YES;
        }
        
        return NO;
    }
    
    return YES;
}

- (PDGesturedTableViewCellSlidingFraction *)currentSlidingFractionForArray:(NSArray *)fractionsArray {
    for (PDGesturedTableViewCellSlidingFraction * fraction in fractionsArray) {
        if (fabsf(self.frame.origin.x/self.frame.size.width) >= fabsf(fraction.activationFraction)) {
            return fraction;
        }
    }
    
    return nil;
}

- (void)sortSlidingFractions {
    NSSortDescriptor * leftFractionsSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"activationFraction" ascending:NO];
    [self.leftSlidingFractions sortUsingDescriptors:@[leftFractionsSortDescriptor]];
    
    NSSortDescriptor * rightFractionsSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"activationFraction" ascending:YES];
    [self.rightSlidingFractions sortUsingDescriptors:@[rightFractionsSortDescriptor]];
}

- (void)slideCell:(UIPanGestureRecognizer *)panGestureRecognizer {
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        originalHorizontalCenter = self.center.x;
        
        [self sortSlidingFractions];
        
        [self.slidingView setFrame:CGRectMake(0, self.frame.origin.y, self.frame.size.width, self.frame.size.height)];
        [self.gesturedTableView insertSubview:self.slidingView atIndex:0];
    } else if (panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        CGFloat horizontalTranslation = [panGestureRecognizer translationInView:self].x;
        
        if ([self.leftSlidingFractions count] == 0 && self.frame.origin.x+horizontalTranslation > 0) horizontalTranslation = 0;
        else if ([self.rightSlidingFractions count] == 0 && self.frame.origin.x+horizontalTranslation < 0) horizontalTranslation = 0;
        
        CGFloat retention = 0;
        
        if (self.bouncesAtLastSlidingFraction && [[currentSlidingFractions firstObject] isEqual:currentSlidingFraction]) {
            retention = (horizontalTranslation-currentSlidingFraction.activationFraction*self.frame.size.width)*0.75;
        }
        
        [self setCenter:CGPointMake(originalHorizontalCenter+horizontalTranslation-retention, self.center.y)];
        
        if (self.frame.origin.x > 0) currentSlidingFractions = self.leftSlidingFractions;
        else if (self.frame.origin.x < 0) currentSlidingFractions = self.rightSlidingFractions;
        
        PDGesturedTableViewCellSlidingFraction * oldSlidingFraction = currentSlidingFraction;
        
        currentSlidingFraction = [self currentSlidingFractionForArray:currentSlidingFractions];
        
        if (![oldSlidingFraction isEqual:currentSlidingFraction]) {
            if (oldSlidingFraction.didDeactivateBlock) oldSlidingFraction.didDeactivateBlock(self.gesturedTableView, self);
            if (currentSlidingFraction.didActivateBlock) currentSlidingFraction.didActivateBlock(self.gesturedTableView, self);
        }
        
        if (currentSlidingFraction) {
            [self.slidingView setBackgroundColor:currentSlidingFraction.color];
            [self.slidingView setIcon:currentSlidingFraction.icon];
            [self.slidingView setIconsAlpha:self.frame.origin.x > 0 ? 1 : -1];
        } else {
            PDGesturedTableViewCellSlidingFraction * firstSlidingFraction = [currentSlidingFractions lastObject];
            
            [self.slidingView setBackgroundColor:[UIColor clearColor]];
            [self.slidingView setIcon:[firstSlidingFraction icon]];
            [self.slidingView setIconsAlpha:fabsf(self.frame.origin.x)/(firstSlidingFraction.activationFraction*self.frame.size.width)];
        }
    } else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if (!currentSlidingFraction && self.frame.origin.x != 0) {
            [UIView animateWithDuration:0.1 animations:^{
                [self setFrame:CGRectMake((self.frame.origin.x > 0 ? -7 : 7), self.frame.origin.y, self.frame.size.width, self.frame.size.height)];
                [self.slidingView setAlpha:0];
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.1 animations:^{
                    [self setFrame:CGRectMake(0, self.frame.origin.y, self.frame.size.width, self.frame.size.height)];
                } completion:^(BOOL finished) {
                    [self.slidingView removeFromSuperview];
                    [self.slidingView setAlpha:1];
                }];
            }];
        } else {
            if (currentSlidingFraction.didReleaseBlock) currentSlidingFraction.didReleaseBlock(self.gesturedTableView, self);
        }
        
        currentSlidingFraction = nil;
    }
}

- (void)setFrame:(CGRect)frame {
    [self.slidingView setFrame:CGRectMake(self.slidingView.frame.origin.x, frame.origin.y, self.slidingView.frame.size.width, self.slidingView.frame.size.height)];
    [super setFrame:(self.gesturedTableView.updating ? CGRectMake(self.frame.origin.x, frame.origin.y, frame.size.width, frame.size.height) : frame)];
}

@end

@implementation PDGesturedTableView

- (id)init {
    if (self = [super init]) {
        [self setAllowsSelection:NO];
        [self setBackgroundView:[UIView new]];
        [self setTableFooterView:[UIView new]];
        [self setSeparatorInset:UIEdgeInsetsZero];
        
        [self setEnabled:YES];
    }
    
    return self;
}

- (void)updateAnimatedly:(BOOL)animatedly {
    [UIView setAnimationsEnabled:animatedly];
    [self beginUpdates];
    [self endUpdates];
    [UIView setAnimationsEnabled:YES];
}

- (void)moveCell:(PDGesturedTableViewCell *)cell toHorizontalPosition:(CGFloat)horizontalPosition duration:(NSTimeInterval)duration completion:(void (^)(void))completion {
    [UIView animateWithDuration:duration animations:^{
        [cell setFrame:CGRectMake(horizontalPosition, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height)];
    } completion:^(BOOL finished) {
        if (completion) completion();
    }];
}

- (void)removeCell:(PDGesturedTableViewCell *)cell completion:(void (^)(void))completion {
    [self moveCell:cell toHorizontalPosition:(cell.frame.origin.x > 0 ? cell.frame.size.width : -cell.frame.size.width) duration:0.4 completion:^{
        [UIView animateWithDuration:0.3 animations:^{
            [cell.slidingView setAlpha:0];
        } completion:^(BOOL finished) {
            NSIndexPath * indexPath = [self indexPathForCell:cell];
            if (completion) completion();
            [self setUpdating:YES];
            [self deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            [self setUpdating:NO];
            [cell removeFromSuperview];
            [cell setFrame:CGRectMake(0, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height)];
            [cell.slidingView removeFromSuperview];
            [cell.slidingView setAlpha:1];
        }];
    }];
}

- (void)replaceCell:(PDGesturedTableViewCell *)cell completion:(void (^)(void))completion {
    [self moveCell:cell toHorizontalPosition:0 duration:0.25 completion:^{
        [cell.slidingView removeFromSuperview];
        if (completion) completion();
    }];
}

- (void)showOrHideBackgroundView {
    [UIView animateWithDuration:0.3 animations:^{
        [self.backgroundView setAlpha:([self isEmpty] ? 1 : 0)];
    }];
}

- (BOOL)isEmpty {
    BOOL isEmpty = YES;
    
    for (NSInteger s = 0; s < [self numberOfSections]; s++) {
        if ([self numberOfRowsInSection:s] > 0) {
            isEmpty = NO;
        }
    }
    
    return isEmpty;
}

- (void)insertRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    [self insertRowsAtIndexPaths:indexPaths withRowAnimation:animation];
    [self showOrHideBackgroundView];
}

- (void)insertSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    [super insertSections:sections withRowAnimation:animation];
    [self showOrHideBackgroundView];
}

- (void)deleteRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    [super deleteRowsAtIndexPaths:indexPaths withRowAnimation:animation];
    [self showOrHideBackgroundView];
}

- (void)deleteSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    [super deleteSections:sections withRowAnimation:animation];
    [self showOrHideBackgroundView];
}

- (void)reloadData {
    [super reloadData];
    [self showOrHideBackgroundView];
}

@end