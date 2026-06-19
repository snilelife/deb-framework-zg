#pragma once

#include <cstdint>
#include <vector>

namespace zg {

struct Point {
    double x = 0.0;
    double y = 0.0;
};

struct Rect {
    double x = 0.0;
    double y = 0.0;
    double width = 0.0;
    double height = 0.0;
};

struct Color {
    double r = 1.0;
    double g = 1.0;
    double b = 1.0;
    double a = 1.0;
};

struct Ball {
    Point center;
    double radius = 12.0;
    int number = -1;
    bool cue = false;
};

struct GuideLine {
    bool valid = false;
    Point start;
    Point end;
};

enum class ScanRoute : std::uint8_t {
    AutoHybrid = 0,
    GuideLock = 1,
    BallGeometry = 2,
    CornerLock = 3
};

enum class PredictionStyle : std::uint8_t {
    Simple = 0,
    Advanced = 1,
    ProVideo = 2
};

struct Settings {
    bool predictionEnabled = true;
    bool cuePredictionEnabled = true;
    bool pocketPredictionEnabled = true;
    bool bankPredictionEnabled = true;
    bool manualPocket = false;
    bool showSideLines = true;
    bool showDetectedBalls = true;
    bool showGhostBall = true;
    double lineLength = 0.86;
    int maxBounces = 3;
    int selectedPocket = 1;
    ScanRoute scanRoute = ScanRoute::AutoHybrid;
    PredictionStyle predictionStyle = PredictionStyle::Advanced;
};

struct GameState {
    Rect table;
    Point cueBall;
    bool hasCueBall = false;
    GuideLine guide;
    std::vector<Ball> balls;
};

struct Line {
    Point start;
    Point end;
    Color color;
    double width = 2.0;
};

struct Circle {
    Point center;
    double radius = 10.0;
    Color color;
    double width = 2.0;
};

struct Result {
    bool valid = false;
    const char *routeName = "unknown";
    const char *styleName = "unknown";
    Rect table;
    int selectedPocket = 0;
    std::vector<Line> lines;
    std::vector<Circle> circles;
};

} // namespace zg
