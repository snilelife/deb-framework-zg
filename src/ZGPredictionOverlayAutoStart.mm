#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "ZGPredictionOverlayController.h"

#ifndef ZG_PREDICTION_OVERLAY_ENABLE_CONSTRUCTOR
#define ZG_PREDICTION_OVERLAY_ENABLE_CONSTRUCTOR 0
#endif

static NSString *const ZGAutoStartEnabledKey = @"ZGPredictionOverlayAutoStartEnabled";
static NSString *const ZGPrimeDefaultTableKey = @"ZGPredictionOverlayPrimeDefaultTable";

static BOOL ZGBoolSetting(NSString *key, BOOL fallback) {
    id userValue = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if ([userValue respondsToSelector:@selector(boolValue)]) {
        return [userValue boolValue];
    }

    id bundleValue = [[NSBundle mainBundle] objectForInfoDictionaryKey:key];
    if ([bundleValue respondsToSelector:@selector(boolValue)]) {
        return [bundleValue boolValue];
    }

    return fallback;
}

static BOOL ZGWindowIsUsable(UIWindow *window) {
    if (!window || window.hidden || window.alpha <= 0.01) return NO;
    if (CGRectIsEmpty(window.bounds)) return NO;
    if (window.bounds.size.width < 80.0 || window.bounds.size.height < 80.0) return NO;
    if (window.windowLevel != UIWindowLevelNormal) return NO;
    return YES;
}

static UIWindow *ZGFirstUsableWindow(NSArray<UIWindow *> *windows, BOOL requireKeyWindow) {
    for (UIWindow *window in windows) {
        if (!ZGWindowIsUsable(window)) continue;
        if (requireKeyWindow && !window.isKeyWindow) continue;
        return window;
    }
    return nil;
}

static UIWindow *ZGBestApplicationWindow(void) {
    UIApplication *application = UIApplication.sharedApplication;
    if (!application) return nil;

    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in application.connectedScenes) {
            if (![scene isKindOfClass:UIWindowScene.class]) continue;
            if (scene.activationState != UISceneActivationStateForegroundActive &&
                scene.activationState != UISceneActivationStateForegroundInactive) {
                continue;
            }

            NSArray<UIWindow *> *windows = ((UIWindowScene *)scene).windows;
            UIWindow *keyWindow = ZGFirstUsableWindow(windows, YES);
            if (keyWindow) return keyWindow;

            UIWindow *usableWindow = ZGFirstUsableWindow(windows, NO);
            if (usableWindow) return usableWindow;
        }
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (ZGWindowIsUsable(application.keyWindow)) {
        return application.keyWindow;
    }
#pragma clang diagnostic pop

    UIWindow *keyWindow = ZGFirstUsableWindow(application.windows, YES);
    if (keyWindow) return keyWindow;

    return ZGFirstUsableWindow(application.windows, NO);
}

static void ZGPrimeDefaultPredictionState(UIWindow *window) {
    if (!ZGBoolSetting(ZGPrimeDefaultTableKey, YES)) return;

    CGRect bounds = window.bounds;
    CGFloat insetX = MAX(24.0, bounds.size.width * 0.06);
    CGFloat insetY = MAX(62.0, bounds.size.height * 0.18);
    ZGOverlayRect table = {
        insetX,
        insetY,
        MAX(1.0, bounds.size.width - insetX * 2.0),
        MAX(1.0, bounds.size.height - insetY * 2.0)
    };
    ZGOverlayPoint cue = {
        table.x + table.width * 0.24,
        table.y + table.height * 0.50
    };
    ZGOverlayGuideLine guide = { NO, { 0.0, 0.0 }, { 0.0, 0.0 } };

    [ZGPredictionOverlayController updateTable:table
                                       cueBall:cue
                                    hasCueBall:YES
                                         balls:NULL
                                         count:0
                                         guide:guide];
}

@interface ZGPredictionOverlayAutoStarter : NSObject
@property (nonatomic) BOOL installed;
@property (nonatomic) BOOL attached;
@property (nonatomic) NSInteger remainingAttempts;
@end

@implementation ZGPredictionOverlayAutoStarter

+ (instancetype)sharedStarter {
    static ZGPredictionOverlayAutoStarter *starter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        starter = [[ZGPredictionOverlayAutoStarter alloc] init];
    });
    return starter;
}

- (void)install {
    if (!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self install];
        });
        return;
    }

    if (self.installed) return;
    self.installed = YES;
    self.remainingAttempts = 80;

    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center addObserver:self selector:@selector(applicationBecameReady:) name:UIApplicationDidFinishLaunchingNotification object:nil];
    [center addObserver:self selector:@selector(applicationBecameReady:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [center addObserver:self selector:@selector(applicationBecameReady:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [center addObserver:self selector:@selector(applicationBecameReady:) name:UIWindowDidBecomeKeyNotification object:nil];
    if (@available(iOS 13.0, *)) {
        [center addObserver:self selector:@selector(applicationBecameReady:) name:UISceneDidActivateNotification object:nil];
    }

    [self attachSoon];
}

- (void)applicationBecameReady:(NSNotification *)notification {
    self.remainingAttempts = MAX(self.remainingAttempts, 20);
    self.attached = NO;
    [self attachSoon];
}

- (void)attachSoon {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(250 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        [self attachNow];
    });
}

- (void)attachNow {
    if (!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self attachNow];
        });
        return;
    }

    if (!ZGBoolSetting(ZGAutoStartEnabledKey, YES)) return;

    UIWindow *window = ZGBestApplicationWindow();
    if (window) {
        [ZGPredictionOverlayController startInWindow:window];
        ZGPrimeDefaultPredictionState(window);
        self.attached = YES;
        self.remainingAttempts = 0;
        return;
    }

    if (self.remainingAttempts > 0) {
        self.remainingAttempts -= 1;
        [self attachSoon];
    }
}

- (void)setAutoStartEnabled:(BOOL)enabled {
    [NSUserDefaults.standardUserDefaults setBool:enabled forKey:ZGAutoStartEnabledKey];
    [NSUserDefaults.standardUserDefaults synchronize];

    if (enabled) {
        self.remainingAttempts = MAX(self.remainingAttempts, 20);
        [self attachSoon];
    } else {
        [ZGPredictionOverlayController stop];
        self.attached = NO;
    }
}

@end

extern "C" __attribute__((visibility("default")))
void ZGPredictionOverlayAutoAttachNow(void) {
    [[ZGPredictionOverlayAutoStarter sharedStarter] install];
    [[ZGPredictionOverlayAutoStarter sharedStarter] attachNow];
}

extern "C" __attribute__((visibility("default")))
void ZGPredictionOverlayAutoStartSetEnabled(BOOL enabled) {
    [[ZGPredictionOverlayAutoStarter sharedStarter] setAutoStartEnabled:enabled];
}

#if ZG_PREDICTION_OVERLAY_ENABLE_CONSTRUCTOR
__attribute__((constructor))
static void ZGPredictionOverlayAutoStartConstructor(void) {
    @autoreleasepool {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[ZGPredictionOverlayAutoStarter sharedStarter] install];
        });
    }
}
#endif
