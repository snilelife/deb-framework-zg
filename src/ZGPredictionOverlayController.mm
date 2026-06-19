#import "ZGPredictionOverlayController.h"

#include "ZGPredictionEngine.hpp"

static NSString *ZGOnOff(BOOL value) {
    return value ? @"ON" : @"OFF";
}

static NSString *ZGRouteName(ZGScanRoute route) {
    switch (route) {
        case ZGScanRouteGuideLock: return @"GUIDE";
        case ZGScanRouteBallGeometry: return @"BALL";
        case ZGScanRouteCornerLock: return @"CORNER";
        case ZGScanRouteAutoHybrid:
        default: return @"AUTO";
    }
}

static NSString *ZGStyleName(ZGPredictionStyle style) {
    switch (style) {
        case ZGPredictionStyleSimple: return @"SIMPLE";
        case ZGPredictionStyleProVideo: return @"VIDEO";
        case ZGPredictionStyleAdvanced:
        default: return @"ADVANCED";
    }
}

static NSString *ZGPocketName(NSInteger pocket, BOOL manual) {
    if (!manual) return @"AUTO";
    NSArray<NSString *> *names = @[@"TOP L", @"TOP M", @"TOP R", @"BOT L", @"BOT M", @"BOT R"];
    NSInteger index = MAX(0, MIN((NSInteger)names.count - 1, pocket));
    return names[index];
}

@interface ZGPredictionOverlaySettings ()
- (zg::Settings)zg_settings;
@end

@implementation ZGPredictionOverlaySettings

+ (instancetype)defaults {
    ZGPredictionOverlaySettings *settings = [[ZGPredictionOverlaySettings alloc] init];
    settings.predictionEnabled = YES;
    settings.cuePredictionEnabled = YES;
    settings.pocketPredictionEnabled = YES;
    settings.bankPredictionEnabled = YES;
    settings.manualPocket = NO;
    settings.showSideLines = YES;
    settings.showDetectedBalls = YES;
    settings.showGhostBall = YES;
    settings.lineLength = 0.86;
    settings.maxBounces = 3;
    settings.selectedPocket = 1;
    settings.scanRoute = ZGScanRouteAutoHybrid;
    settings.predictionStyle = ZGPredictionStyleAdvanced;
    return settings;
}

- (id)copyWithZone:(NSZone *)zone {
    ZGPredictionOverlaySettings *copy = [[[self class] allocWithZone:zone] init];
    copy.predictionEnabled = self.predictionEnabled;
    copy.cuePredictionEnabled = self.cuePredictionEnabled;
    copy.pocketPredictionEnabled = self.pocketPredictionEnabled;
    copy.bankPredictionEnabled = self.bankPredictionEnabled;
    copy.manualPocket = self.manualPocket;
    copy.showSideLines = self.showSideLines;
    copy.showDetectedBalls = self.showDetectedBalls;
    copy.showGhostBall = self.showGhostBall;
    copy.lineLength = self.lineLength;
    copy.maxBounces = self.maxBounces;
    copy.selectedPocket = self.selectedPocket;
    copy.scanRoute = self.scanRoute;
    copy.predictionStyle = self.predictionStyle;
    return copy;
}

- (zg::Settings)zg_settings {
    zg::Settings out;
    out.predictionEnabled = self.predictionEnabled;
    out.cuePredictionEnabled = self.cuePredictionEnabled;
    out.pocketPredictionEnabled = self.pocketPredictionEnabled;
    out.bankPredictionEnabled = self.bankPredictionEnabled;
    out.manualPocket = self.manualPocket;
    out.showSideLines = self.showSideLines;
    out.showDetectedBalls = self.showDetectedBalls;
    out.showGhostBall = self.showGhostBall;
    out.lineLength = self.lineLength;
    out.maxBounces = (int)self.maxBounces;
    out.selectedPocket = (int)self.selectedPocket;
    out.scanRoute = static_cast<zg::ScanRoute>(self.scanRoute);
    out.predictionStyle = static_cast<zg::PredictionStyle>(self.predictionStyle);
    return out;
}

@end

@interface ZGPredictionCanvasView : UIView {
@private
    zg::Result _result;
}
- (void)setPredictionResult:(const zg::Result &)result;
@end

@implementation ZGPredictionCanvasView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.userInteractionEnabled = NO;
        self.opaque = NO;
    }
    return self;
}

- (void)setPredictionResult:(const zg::Result &)result {
    _result = result;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx || !_result.valid) return;

    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);

    for (const auto &line : _result.lines) {
        CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:line.color.r green:line.color.g blue:line.color.b alpha:line.color.a].CGColor);
        CGContextSetLineWidth(ctx, line.width);
        CGContextMoveToPoint(ctx, line.start.x, line.start.y);
        CGContextAddLineToPoint(ctx, line.end.x, line.end.y);
        CGContextStrokePath(ctx);
    }

    for (const auto &circle : _result.circles) {
        CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:circle.color.r green:circle.color.g blue:circle.color.b alpha:circle.color.a].CGColor);
        CGContextSetLineWidth(ctx, circle.width);
        CGRect oval = CGRectMake(circle.center.x - circle.radius, circle.center.y - circle.radius, circle.radius * 2.0, circle.radius * 2.0);
        CGContextStrokeEllipseInRect(ctx, oval);
    }
}

@end

@interface ZGPredictionOverlayView : UIView {
@private
    zg::PredictionEngine _engine;
    zg::GameState _state;
    zg::Result _lastResult;
}
@property (nonatomic, strong) ZGPredictionOverlaySettings *settings;
@property (nonatomic, strong) ZGPredictionCanvasView *canvasView;
@property (nonatomic, strong) UIView *bubbleView;
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *enabledButton;
@property (nonatomic, strong) UIButton *cueButton;
@property (nonatomic, strong) UIButton *pocketPathButton;
@property (nonatomic, strong) UIButton *bankPathButton;
@property (nonatomic, strong) UIButton *routeButton;
@property (nonatomic, strong) UIButton *styleButton;
@property (nonatomic, strong) UIButton *selectedPocketButton;
@property (nonatomic, strong) UIButton *bounceButton;
@property (nonatomic, strong) UIButton *lengthButton;
@property (nonatomic, strong) UIButton *ghostButton;
@property (nonatomic, strong) UIButton *ballsButton;
@property (nonatomic, strong) UIButton *sideLinesButton;
@end

@implementation ZGPredictionOverlayView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.settings = [ZGPredictionOverlaySettings defaults];

        _canvasView = [[ZGPredictionCanvasView alloc] initWithFrame:self.bounds];
        _canvasView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_canvasView];

        [self buildBubble];
        [self buildMenu];
        [self recompute];
    }
    return self;
}

- (void)buildBubble {
    _bubbleView = [[UIView alloc] initWithFrame:CGRectMake(18, 80, 58, 58)];
    _bubbleView.backgroundColor = [UIColor colorWithRed:0.02 green:0.08 blue:0.12 alpha:0.92];
    _bubbleView.layer.cornerRadius = 29;
    _bubbleView.layer.borderColor = [UIColor colorWithRed:0.15 green:0.88 blue:1 alpha:0.74].CGColor;
    _bubbleView.layer.borderWidth = 1.5;
    _bubbleView.layer.shadowColor = UIColor.cyanColor.CGColor;
    _bubbleView.layer.shadowOpacity = 0.35;
    _bubbleView.layer.shadowRadius = 10;

    UILabel *label = [[UILabel alloc] initWithFrame:_bubbleView.bounds];
    label.text = @"ZG";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBlack];
    [_bubbleView addSubview:label];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleMenu)];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panBubble:)];
    [_bubbleView addGestureRecognizer:tap];
    [_bubbleView addGestureRecognizer:pan];
    [self addSubview:_bubbleView];
}

- (UIButton *)buttonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBlack];
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    button.titleLabel.minimumScaleFactor = 0.72;
    button.backgroundColor = [UIColor colorWithRed:0.04 green:0.40 blue:0.66 alpha:0.95];
    button.layer.cornerRadius = 10;
    button.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)buildMenu {
    CGFloat menuWidth = MIN(326.0, MAX(286.0, self.bounds.size.width - 36.0));
    CGFloat menuHeight = MIN(458.0, MAX(310.0, self.bounds.size.height - 110.0));
    CGFloat menuY = MIN(150.0, MAX(70.0, self.bounds.size.height - menuHeight - 20.0));
    _menuView = [[UIView alloc] initWithFrame:CGRectMake(18, menuY, menuWidth, menuHeight)];
    _menuView.hidden = YES;
    _menuView.backgroundColor = [UIColor colorWithRed:0.005 green:0.008 blue:0.012 alpha:0.94];
    _menuView.layer.cornerRadius = 18;
    _menuView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.16].CGColor;
    _menuView.layer.borderWidth = 1;
    _menuView.layer.shadowColor = UIColor.cyanColor.CGColor;
    _menuView.layer.shadowOpacity = 0.18;
    _menuView.layer.shadowRadius = 18;

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 12, menuWidth - 32, 28)];
    title.text = @"ZG Prediction Overlay";
    title.textColor = UIColor.whiteColor;
    title.font = [UIFont systemFontOfSize:19 weight:UIFontWeightBlack];
    [_menuView addSubview:title];

    _statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 40, menuWidth - 32, 20)];
    _statusLabel.textColor = [UIColor colorWithRed:0.18 green:0.90 blue:1 alpha:1];
    _statusLabel.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightBold];
    [_menuView addSubview:_statusLabel];

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(16, 72, menuWidth - 32, menuHeight - 104)];
    scrollView.showsVerticalScrollIndicator = YES;
    [_menuView addSubview:scrollView];

    const CGFloat rowHeight = 42.0;
    const CGFloat spacing = 8.0;
    const NSInteger rowCount = 12;
    CGFloat stackHeight = rowCount * rowHeight + (rowCount - 1) * spacing;
    UIStackView *stack = [[UIStackView alloc] initWithFrame:CGRectMake(0, 0, scrollView.bounds.size.width, stackHeight)];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = spacing;
    stack.distribution = UIStackViewDistributionFillEqually;
    [scrollView addSubview:stack];
    scrollView.contentSize = CGSizeMake(scrollView.bounds.size.width, stackHeight);

    self.enabledButton = [self buttonWithTitle:@"" action:@selector(togglePredictions)];
    self.cueButton = [self buttonWithTitle:@"" action:@selector(toggleCuePrediction)];
    self.pocketPathButton = [self buttonWithTitle:@"" action:@selector(togglePocketPrediction)];
    self.bankPathButton = [self buttonWithTitle:@"" action:@selector(toggleBankPrediction)];
    self.routeButton = [self buttonWithTitle:@"" action:@selector(cycleRoute)];
    self.styleButton = [self buttonWithTitle:@"" action:@selector(cycleStyle)];
    self.selectedPocketButton = [self buttonWithTitle:@"" action:@selector(nextPocket)];
    self.bounceButton = [self buttonWithTitle:@"" action:@selector(nextBounces)];
    self.lengthButton = [self buttonWithTitle:@"" action:@selector(nextLineLength)];
    self.ghostButton = [self buttonWithTitle:@"" action:@selector(toggleGhost)];
    self.ballsButton = [self buttonWithTitle:@"" action:@selector(toggleBalls)];
    self.sideLinesButton = [self buttonWithTitle:@"" action:@selector(toggleSideLines)];

    [stack addArrangedSubview:self.enabledButton];
    [stack addArrangedSubview:self.cueButton];
    [stack addArrangedSubview:self.pocketPathButton];
    [stack addArrangedSubview:self.bankPathButton];
    [stack addArrangedSubview:self.routeButton];
    [stack addArrangedSubview:self.styleButton];
    [stack addArrangedSubview:self.selectedPocketButton];
    [stack addArrangedSubview:self.bounceButton];
    [stack addArrangedSubview:self.lengthButton];
    [stack addArrangedSubview:self.ghostButton];
    [stack addArrangedSubview:self.ballsButton];
    [stack addArrangedSubview:self.sideLinesButton];

    UILabel *footer = [[UILabel alloc] initWithFrame:CGRectMake(16, menuHeight - 26, menuWidth - 32, 16)];
    footer.text = @"created by zav G";
    footer.textAlignment = NSTextAlignmentCenter;
    footer.textColor = [UIColor colorWithWhite:1 alpha:0.54];
    footer.font = [UIFont systemFontOfSize:10 weight:UIFontWeightBold];
    [_menuView addSubview:footer];

    [self addSubview:_menuView];
    [self updateMenuState];
}

- (void)toggleMenu {
    _menuView.hidden = !_menuView.hidden;
}

- (void)panBubble:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self];
    CGPoint center = _bubbleView.center;
    center.x += translation.x;
    center.y += translation.y;
    center.x = MAX(34, MIN(self.bounds.size.width - 34, center.x));
    center.y = MAX(34, MIN(self.bounds.size.height - 34, center.y));
    _bubbleView.center = center;
    [recognizer setTranslation:CGPointZero inView:self];
}

- (void)togglePredictions { self.settings.predictionEnabled = !self.settings.predictionEnabled; [self recompute]; }
- (void)toggleCuePrediction { self.settings.cuePredictionEnabled = !self.settings.cuePredictionEnabled; [self recompute]; }
- (void)togglePocketPrediction { self.settings.pocketPredictionEnabled = !self.settings.pocketPredictionEnabled; [self recompute]; }
- (void)toggleBankPrediction { self.settings.bankPredictionEnabled = !self.settings.bankPredictionEnabled; [self recompute]; }

- (void)cycleRoute {
    self.settings.scanRoute = (ZGScanRoute)((self.settings.scanRoute + 1) % 4);
    [self recompute];
}

- (void)cycleStyle {
    self.settings.predictionStyle = (ZGPredictionStyle)((self.settings.predictionStyle + 1) % 3);
    [self recompute];
}

- (void)nextPocket {
    if (!self.settings.manualPocket) {
        self.settings.manualPocket = YES;
        self.settings.selectedPocket = 0;
    } else {
        self.settings.selectedPocket += 1;
        if (self.settings.selectedPocket >= 6) {
            self.settings.selectedPocket = 0;
            self.settings.manualPocket = NO;
        }
    }
    [self recompute];
}

- (void)nextBounces {
    self.settings.maxBounces = (self.settings.maxBounces + 1) % 7;
    [self recompute];
}

- (void)nextLineLength {
    self.settings.lineLength += 0.10;
    if (self.settings.lineLength > 1.05) self.settings.lineLength = 0.35;
    [self recompute];
}

- (void)toggleGhost { self.settings.showGhostBall = !self.settings.showGhostBall; [self recompute]; }
- (void)toggleBalls { self.settings.showDetectedBalls = !self.settings.showDetectedBalls; [self recompute]; }
- (void)toggleSideLines { self.settings.showSideLines = !self.settings.showSideLines; [self recompute]; }

- (void)recompute {
    _lastResult = _engine.compute(_state, [self.settings zg_settings]);
    [self.canvasView setPredictionResult:_lastResult];
    [self updateMenuState];
}

- (void)updateButton:(UIButton *)button title:(NSString *)title active:(BOOL)active {
    if (!button) return;
    [button setTitle:title forState:UIControlStateNormal];
    if (active) {
        button.backgroundColor = [UIColor colorWithRed:0.00 green:0.52 blue:0.76 alpha:0.96];
        button.layer.borderColor = [UIColor colorWithRed:0.18 green:0.92 blue:1.0 alpha:0.52].CGColor;
    } else {
        button.backgroundColor = [UIColor colorWithRed:0.10 green:0.11 blue:0.14 alpha:0.96];
        button.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.12].CGColor;
    }
    button.layer.borderWidth = 1.0;
}

- (void)updateMenuState {
    [self updateButton:self.enabledButton
                 title:[NSString stringWithFormat:@"OVERLAY %@", ZGOnOff(self.settings.predictionEnabled)]
                active:self.settings.predictionEnabled];
    [self updateButton:self.cueButton
                 title:[NSString stringWithFormat:@"CUE LINE %@", ZGOnOff(self.settings.cuePredictionEnabled)]
                active:self.settings.cuePredictionEnabled];
    [self updateButton:self.pocketPathButton
                 title:[NSString stringWithFormat:@"POCKET PATH %@", ZGOnOff(self.settings.pocketPredictionEnabled)]
                active:self.settings.pocketPredictionEnabled];
    [self updateButton:self.bankPathButton
                 title:[NSString stringWithFormat:@"BANK PATHS %@", ZGOnOff(self.settings.bankPredictionEnabled)]
                active:self.settings.bankPredictionEnabled];
    [self updateButton:self.routeButton
                 title:[NSString stringWithFormat:@"ROUTE %@", ZGRouteName(self.settings.scanRoute)]
                active:YES];
    [self updateButton:self.styleButton
                 title:[NSString stringWithFormat:@"STYLE %@", ZGStyleName(self.settings.predictionStyle)]
                active:YES];
    [self updateButton:self.selectedPocketButton
                 title:[NSString stringWithFormat:@"POCKET %@", ZGPocketName(self.settings.selectedPocket, self.settings.manualPocket)]
                active:self.settings.manualPocket];
    [self updateButton:self.bounceButton
                 title:[NSString stringWithFormat:@"BOUNCES %ld", (long)self.settings.maxBounces]
                active:self.settings.maxBounces > 0];
    [self updateButton:self.lengthButton
                 title:[NSString stringWithFormat:@"LINE LENGTH %.0f%%", self.settings.lineLength * 100.0]
                active:YES];
    [self updateButton:self.ghostButton
                 title:[NSString stringWithFormat:@"GHOST BALL %@", ZGOnOff(self.settings.showGhostBall)]
                active:self.settings.showGhostBall];
    [self updateButton:self.ballsButton
                 title:[NSString stringWithFormat:@"BALL MARKERS %@", ZGOnOff(self.settings.showDetectedBalls)]
                active:self.settings.showDetectedBalls];
    [self updateButton:self.sideLinesButton
                 title:[NSString stringWithFormat:@"CENTERLINES %@", ZGOnOff(self.settings.showSideLines)]
                active:self.settings.showSideLines];

    self.statusLabel.text = [NSString stringWithFormat:@"LIVE GEOMETRY | %@ | %@ | %@",
                             ZGRouteName(self.settings.scanRoute),
                             ZGStyleName(self.settings.predictionStyle),
                             ZGPocketName(self.settings.selectedPocket, self.settings.manualPocket)];
}

- (void)updateTable:(ZGOverlayRect)table
            cueBall:(ZGOverlayPoint)cueBall
         hasCueBall:(BOOL)hasCueBall
              balls:(const ZGOverlayBall *)balls
              count:(NSUInteger)count
              guide:(ZGOverlayGuideLine)guide {
    _state.table = {table.x, table.y, table.width, table.height};
    _state.cueBall = {cueBall.x, cueBall.y};
    _state.hasCueBall = hasCueBall;
    _state.guide.valid = guide.valid;
    _state.guide.start = {guide.start.x, guide.start.y};
    _state.guide.end = {guide.end.x, guide.end.y};
    _state.balls.clear();
    if (!balls && count > 0) {
        count = 0;
    }
    for (NSUInteger i = 0; i < count; ++i) {
        zg::Ball ball;
        ball.center = {balls[i].center.x, balls[i].center.y};
        ball.radius = balls[i].radius;
        ball.number = (int)balls[i].number;
        ball.cue = balls[i].cue;
        _state.balls.push_back(ball);
    }
    [self recompute];
}

@end

static ZGPredictionOverlayView *ZGSharedOverlayView = nil;
static ZGPredictionOverlaySettings *ZGSharedSettings = nil;

@implementation ZGPredictionOverlayController

+ (void)startInWindow:(UIWindow *)window {
    if (!window) return;
    [self startInView:window];
}

+ (void)startInView:(UIView *)view {
    if (!view) return;
    if (ZGSharedOverlayView) {
        [ZGSharedOverlayView removeFromSuperview];
        ZGSharedOverlayView = nil;
    }
    ZGSharedOverlayView = [[ZGPredictionOverlayView alloc] initWithFrame:view.bounds];
    if (ZGSharedSettings) {
        ZGSharedOverlayView.settings = [ZGSharedSettings copy];
        [ZGSharedOverlayView recompute];
    }
    [view addSubview:ZGSharedOverlayView];
}

+ (void)stop {
    [ZGSharedOverlayView removeFromSuperview];
    ZGSharedOverlayView = nil;
}

+ (void)setVisible:(BOOL)visible {
    ZGSharedOverlayView.hidden = !visible;
}

+ (ZGPredictionOverlaySettings *)settings {
    if (ZGSharedOverlayView) return [ZGSharedOverlayView.settings copy];
    if (!ZGSharedSettings) ZGSharedSettings = [ZGPredictionOverlaySettings defaults];
    return [ZGSharedSettings copy];
}

+ (void)applySettings:(ZGPredictionOverlaySettings *)settings {
    ZGSharedSettings = [settings copy];
    if (ZGSharedOverlayView) {
        ZGSharedOverlayView.settings = [settings copy];
        [ZGSharedOverlayView recompute];
    }
}

+ (void)updateTable:(ZGOverlayRect)table
            cueBall:(ZGOverlayPoint)cueBall
         hasCueBall:(BOOL)hasCueBall
              balls:(const ZGOverlayBall *)balls
              count:(NSUInteger)count
              guide:(ZGOverlayGuideLine)guide {
    [ZGSharedOverlayView updateTable:table cueBall:cueBall hasCueBall:hasCueBall balls:balls count:count guide:guide];
}

@end
