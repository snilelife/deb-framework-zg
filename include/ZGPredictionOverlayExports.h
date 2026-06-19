#pragma once

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "ZGPredictionOverlayController.h"

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

__attribute__((visibility("default")))
void ZGPredictionOverlayStartInWindow(UIWindow *window);

__attribute__((visibility("default")))
void ZGPredictionOverlayStartInView(UIView *view);

__attribute__((visibility("default")))
void ZGPredictionOverlayStop(void);

__attribute__((visibility("default")))
void ZGPredictionOverlaySetVisible(BOOL visible);

__attribute__((visibility("default")))
ZGPredictionOverlaySettings *ZGPredictionOverlayCopySettings(void);

__attribute__((visibility("default")))
void ZGPredictionOverlayApplySettings(ZGPredictionOverlaySettings *settings);

__attribute__((visibility("default")))
void ZGPredictionOverlayUpdateTable(ZGOverlayRect table,
                                    ZGOverlayPoint cueBall,
                                    BOOL hasCueBall,
                                    const ZGOverlayBall *_Nullable balls,
                                    NSUInteger count,
                                    ZGOverlayGuideLine guide);

__attribute__((visibility("default")))
void ZGPredictionOverlayAutoAttachNow(void);

__attribute__((visibility("default")))
void ZGPredictionOverlayAutoStartSetEnabled(BOOL enabled);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
