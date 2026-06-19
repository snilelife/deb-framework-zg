#import <UIKit/UIKit.h>

#import "ZGPredictionOverlayExports.h"

extern "C" __attribute__((visibility("default")))
void ZGPredictionOverlayStartInWindow(UIWindow *window) {
    [ZGPredictionOverlayController startInWindow:window];
}

extern "C" __attribute__((visibility("default")))
void ZGPredictionOverlayStartInView(UIView *view) {
    [ZGPredictionOverlayController startInView:view];
}

extern "C" __attribute__((visibility("default")))
void ZGPredictionOverlayStop(void) {
    [ZGPredictionOverlayController stop];
}

extern "C" __attribute__((visibility("default")))
void ZGPredictionOverlaySetVisible(BOOL visible) {
    [ZGPredictionOverlayController setVisible:visible];
}

extern "C" __attribute__((visibility("default")))
ZGPredictionOverlaySettings *ZGPredictionOverlayCopySettings(void) {
    return [ZGPredictionOverlayController settings];
}

extern "C" __attribute__((visibility("default")))
void ZGPredictionOverlayApplySettings(ZGPredictionOverlaySettings *settings) {
    [ZGPredictionOverlayController applySettings:settings];
}

extern "C" __attribute__((visibility("default")))
void ZGPredictionOverlayUpdateTable(ZGOverlayRect table,
                                    ZGOverlayPoint cueBall,
                                    BOOL hasCueBall,
                                    const ZGOverlayBall *balls,
                                    NSUInteger count,
                                    ZGOverlayGuideLine guide) {
    [ZGPredictionOverlayController updateTable:table
                                       cueBall:cueBall
                                    hasCueBall:hasCueBall
                                         balls:balls
                                         count:count
                                         guide:guide];
}
