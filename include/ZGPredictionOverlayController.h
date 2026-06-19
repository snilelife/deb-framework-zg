#pragma once

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ZGScanRoute) {
    ZGScanRouteAutoHybrid = 0,
    ZGScanRouteGuideLock = 1,
    ZGScanRouteBallGeometry = 2,
    ZGScanRouteCornerLock = 3
};

typedef NS_ENUM(NSInteger, ZGPredictionStyle) {
    ZGPredictionStyleSimple = 0,
    ZGPredictionStyleAdvanced = 1,
    ZGPredictionStyleProVideo = 2
};

typedef struct {
    CGFloat x;
    CGFloat y;
} ZGOverlayPoint;

typedef struct {
    CGFloat x;
    CGFloat y;
    CGFloat width;
    CGFloat height;
} ZGOverlayRect;

typedef struct {
    ZGOverlayPoint center;
    CGFloat radius;
    NSInteger number;
    BOOL cue;
} ZGOverlayBall;

typedef struct {
    BOOL valid;
    ZGOverlayPoint start;
    ZGOverlayPoint end;
} ZGOverlayGuideLine;

@interface ZGPredictionOverlaySettings : NSObject <NSCopying>
@property (nonatomic) BOOL predictionEnabled;
@property (nonatomic) BOOL cuePredictionEnabled;
@property (nonatomic) BOOL pocketPredictionEnabled;
@property (nonatomic) BOOL bankPredictionEnabled;
@property (nonatomic) BOOL manualPocket;
@property (nonatomic) BOOL showSideLines;
@property (nonatomic) BOOL showDetectedBalls;
@property (nonatomic) BOOL showGhostBall;
@property (nonatomic) CGFloat lineLength;
@property (nonatomic) NSInteger maxBounces;
@property (nonatomic) NSInteger selectedPocket;
@property (nonatomic) ZGScanRoute scanRoute;
@property (nonatomic) ZGPredictionStyle predictionStyle;
+ (instancetype)defaults;
@end

@interface ZGPredictionOverlayController : NSObject

+ (void)startInWindow:(UIWindow *)window;
+ (void)startInView:(UIView *)view;
+ (void)stop;
+ (void)setVisible:(BOOL)visible;
+ (ZGPredictionOverlaySettings *)settings;
+ (void)applySettings:(ZGPredictionOverlaySettings *)settings;

+ (void)updateTable:(ZGOverlayRect)table
            cueBall:(ZGOverlayPoint)cueBall
        hasCueBall:(BOOL)hasCueBall
             balls:(const ZGOverlayBall *_Nullable)balls
             count:(NSUInteger)count
             guide:(ZGOverlayGuideLine)guide;

@end

NS_ASSUME_NONNULL_END
