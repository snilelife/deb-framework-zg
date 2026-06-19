#import <UIKit/UIKit.h>
#import "ZGPredictionOverlayController.h"

void ZGStartOverlayExample(UIWindow *window) {
    [ZGPredictionOverlayController startInWindow:window];

    ZGPredictionOverlaySettings *settings = [ZGPredictionOverlayController settings];
    settings.predictionEnabled = YES;
    settings.cuePredictionEnabled = YES;
    settings.pocketPredictionEnabled = YES;
    settings.bankPredictionEnabled = YES;
    settings.predictionStyle = ZGPredictionStyleProVideo;
    settings.scanRoute = ZGScanRouteAutoHybrid;
    settings.maxBounces = 3;
    [ZGPredictionOverlayController applySettings:settings];
}

void ZGUpdateOverlayExample(CGRect viewBounds) {
    ZGOverlayRect table = {
        viewBounds.size.width * 0.10,
        viewBounds.size.height * 0.24,
        viewBounds.size.width * 0.80,
        viewBounds.size.height * 0.45
    };

    ZGOverlayPoint cue = {table.x + table.width * 0.25, table.y + table.height * 0.52};
    ZGOverlayBall balls[] = {
        {{table.x + table.width * 0.62, table.y + table.height * 0.42}, 12, 3, NO},
        {{table.x + table.width * 0.68, table.y + table.height * 0.48}, 12, 8, NO},
        {cue, 12, 0, YES}
    };
    ZGOverlayGuideLine guide = {YES, cue, {table.x + table.width * 0.86, table.y + table.height * 0.38}};

    [ZGPredictionOverlayController updateTable:table
                                       cueBall:cue
                                    hasCueBall:YES
                                         balls:balls
                                         count:3
                                         guide:guide];
}
