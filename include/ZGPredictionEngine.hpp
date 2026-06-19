#pragma once

#include "ZGOverlayTypes.hpp"

namespace zg {

class PredictionEngine {
public:
    Result compute(const GameState &state, const Settings &settings) const;

private:
    struct ShotChoice {
        Point cue;
        Point object;
        Point pocket;
        Point ghost;
        double score = 0.0;
        int pocketIndex = 0;
        double ballRadius = 12.0;
    };

    static const char *routeName(ScanRoute route);
    static const char *styleName(PredictionStyle style);
    static std::vector<Point> pocketPoints(const Rect &table);
    static Point nearestPocket(const Point &point, const std::vector<Point> &pockets);
    static Point pointToward(const Point &start, const Point &end, double distance);
    static Point clamp(const Point &point, const Rect &rect);
    static double distance(const Point &a, const Point &b);
    static double cross(const Point &a, const Point &b);
    static Line makeLine(const Point &start, const Point &end, Color color, double width);
    static Circle makeCircle(const Point &center, double radius, Color color, double width);
    static void addStyledLine(Result &result, const Point &start, const Point &end, Color color, double width, PredictionStyle style);
    static std::vector<Point> bouncePath(const Point &start, const Point &target, const Rect &table, int count);
    static std::vector<Point> cueAfterHitPath(const ShotChoice &choice, const Rect &table, int count);
    static std::vector<std::vector<Point>> bankGuides(const Point &object, const Point &pocket, const Rect &table);
    static bool railGuide(const Point &object, const Point &pocket, const Rect &table, int rail, std::vector<Point> &out);
    static double guideLength(const std::vector<Point> &guide);
    static ShotChoice chooseShot(const GameState &state, const Settings &settings, const std::vector<Point> &pockets);
};

} // namespace zg
