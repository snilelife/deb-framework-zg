#include "ZGPredictionEngine.hpp"

#include <algorithm>
#include <cmath>
#include <limits>

namespace zg {
namespace {
constexpr double kEpsilon = 0.0001;
constexpr Color kWhite{1.0, 1.0, 1.0, 0.94};
constexpr Color kCyan{0.10, 0.86, 1.0, 0.88};
constexpr Color kGold{1.0, 0.84, 0.10, 0.96};
constexpr Color kGreen{0.70, 1.00, 0.12, 0.70};
constexpr Color kPurple{0.48, 0.38, 1.0, 0.52};
constexpr Color kRed{1.0, 0.20, 0.20, 0.62};
}

Result PredictionEngine::compute(const GameState &state, const Settings &settings) const {
    Result result;
    result.table = state.table;
    result.routeName = routeName(settings.scanRoute);
    result.styleName = styleName(settings.predictionStyle);

    if (!settings.predictionEnabled || state.table.width <= 0.0 || state.table.height <= 0.0) {
        return result;
    }

    const auto pockets = pocketPoints(state.table);
    const int selectedPocket = std::max(0, std::min(settings.selectedPocket, static_cast<int>(pockets.size()) - 1));
    result.selectedPocket = selectedPocket;

    const Point cue = state.hasCueBall
        ? state.cueBall
        : Point{state.table.x + state.table.width * 0.24, state.table.y + state.table.height * 0.5};
    const double ballRadius = std::max(8.0, state.table.width * 0.018);
    const PredictionStyle style = settings.predictionStyle;
    const ScanRoute route = settings.scanRoute;

    if (settings.pocketPredictionEnabled && style == PredictionStyle::ProVideo) {
        for (const auto &pocket : pockets) {
            result.circles.push_back(makeCircle(pocket, std::max(10.0, state.table.width * 0.016), Color{0.08, 0.95, 1.0, 0.46}, 2.0));
        }
    }

    bool usedGuide = false;
    bool usedChoice = false;
    ShotChoice choice;

    if (settings.cuePredictionEnabled &&
        (route == ScanRoute::AutoHybrid || route == ScanRoute::GuideLock) &&
        state.guide.valid) {
        const auto path = bouncePath(state.guide.start, state.guide.end, state.table, std::max(1, settings.maxBounces + 1));
        for (std::size_t i = 0; i + 1 < path.size(); ++i) {
            addStyledLine(result, path[i], path[i + 1],
                          i == 0 ? kWhite : Color{0.18, 0.88, 1.0, 0.74},
                          i == 0 ? (style == PredictionStyle::ProVideo ? 4.2 : 3.2) : 2.2,
                          style);
        }
        usedGuide = true;
    }

    if (!usedGuide && route != ScanRoute::CornerLock) {
        choice = chooseShot(state, settings, pockets);
        usedChoice = choice.ballRadius > 0.0;
    }

    if (!usedGuide && usedChoice) {
        if (settings.cuePredictionEnabled) {
            addStyledLine(result, choice.cue, choice.ghost, kWhite, style == PredictionStyle::ProVideo ? 4.0 : 3.1, style);
        }
        if (settings.pocketPredictionEnabled) {
            addStyledLine(result, choice.object, choice.pocket, kCyan, style == PredictionStyle::ProVideo ? 3.1 : 2.4, style);
        }

        if (style == PredictionStyle::ProVideo) {
            if (settings.cuePredictionEnabled || settings.pocketPredictionEnabled) {
                addStyledLine(result, choice.ghost, choice.object, Color{1.0, 0.84, 0.10, 0.78}, 2.0, style);
            }
            if (settings.bankPredictionEnabled) {
                for (const auto &guide : bankGuides(choice.object, choice.pocket, state.table)) {
                    if (guide.size() == 3) {
                        addStyledLine(result, guide[0], guide[1], Color{0.72, 0.40, 1.0, 0.36}, 1.8, style);
                        addStyledLine(result, guide[1], guide[2], Color{0.72, 0.40, 1.0, 0.36}, 1.8, style);
                    }
                }
            }
        }

        if (settings.showGhostBall) {
            result.circles.push_back(makeCircle(choice.ghost, ballRadius, kGold, style == PredictionStyle::ProVideo ? 3.2 : 2.6));
            if (style == PredictionStyle::ProVideo) {
                result.circles.push_back(makeCircle(choice.object, ballRadius * 1.18, Color{0.10, 0.86, 1.0, 0.66}, 2.2));
            }
        }

        if (settings.cuePredictionEnabled && style != PredictionStyle::Simple) {
            const auto after = cueAfterHitPath(choice, state.table, settings.maxBounces);
            for (std::size_t i = 0; i + 1 < after.size(); ++i) {
                addStyledLine(result, after[i], after[i + 1], kGreen, style == PredictionStyle::ProVideo ? 2.5 : 2.0, style);
            }
        }
    }

    if (!usedGuide && !usedChoice) {
        const Point target = settings.manualPocket ? pockets[selectedPocket] : nearestPocket(cue, pockets);
        const double reach = std::hypot(state.table.width, state.table.height) * settings.lineLength;
        const Point aimEnd = clamp(pointToward(cue, target, reach), state.table);
        if (settings.cuePredictionEnabled) {
            addStyledLine(result, cue, aimEnd, kWhite, style == PredictionStyle::ProVideo ? 3.8 : 2.8, style);
        }
        if (settings.pocketPredictionEnabled && style != PredictionStyle::Simple) {
            addStyledLine(result, aimEnd, target, kCyan, style == PredictionStyle::ProVideo ? 2.8 : 2.2, style);
        }
    }

    if (settings.showSideLines) {
        const double alpha = style == PredictionStyle::ProVideo ? 0.26 : 0.18;
        result.lines.push_back(makeLine(Point{state.table.x, state.table.y + state.table.height * 0.5},
                                        Point{state.table.x + state.table.width, state.table.y + state.table.height * 0.5},
                                        Color{1.0, 0.86, 0.18, alpha}, style == PredictionStyle::ProVideo ? 1.4 : 1.0));
        result.lines.push_back(makeLine(Point{state.table.x + state.table.width * 0.5, state.table.y},
                                        Point{state.table.x + state.table.width * 0.5, state.table.y + state.table.height},
                                        Color{1.0, 0.86, 0.18, alpha}, style == PredictionStyle::ProVideo ? 1.4 : 1.0));
    }

    if (settings.bankPredictionEnabled && style != PredictionStyle::Simple && !usedGuide) {
        const Point bounceStart = usedChoice ? choice.cue : cue;
        const Point bounceTarget = usedChoice ? choice.pocket : pockets[selectedPocket];
        const auto bounces = bouncePath(bounceStart, bounceTarget, state.table, settings.maxBounces);
        for (std::size_t i = 0; i + 1 < bounces.size(); ++i) {
            addStyledLine(result, bounces[i], bounces[i + 1], kPurple, style == PredictionStyle::ProVideo ? 1.9 : 1.5, style);
        }
    }

    result.circles.push_back(makeCircle(cue, ballRadius, kWhite, style == PredictionStyle::ProVideo ? 3.6 : 2.8));
    if (settings.pocketPredictionEnabled) {
        const Point selected = usedChoice ? choice.pocket : pockets[selectedPocket];
        result.circles.push_back(makeCircle(selected, std::max(13.0, state.table.width * (style == PredictionStyle::ProVideo ? 0.030 : 0.023)),
                                            Color{0.1, 0.88, 1.0, 0.94}, style == PredictionStyle::ProVideo ? 4.2 : 3.0));
    }

    if (settings.showDetectedBalls) {
        const std::size_t limit = style == PredictionStyle::ProVideo ? 16 : style == PredictionStyle::Advanced ? 10 : 6;
        for (std::size_t i = 0; i < std::min(limit, state.balls.size()); ++i) {
            const auto &ball = state.balls[i];
            result.circles.push_back(makeCircle(ball.center, ball.radius > 0.0 ? ball.radius : ballRadius,
                                                ball.cue ? Color{1.0, 1.0, 1.0, 0.75} : kRed,
                                                style == PredictionStyle::ProVideo ? 2.2 : 1.7));
        }
    }

    result.valid = true;
    return result;
}

const char *PredictionEngine::routeName(ScanRoute route) {
    switch (route) {
        case ScanRoute::GuideLock: return "guide_lock";
        case ScanRoute::BallGeometry: return "ball_geometry";
        case ScanRoute::CornerLock: return "corner_lock";
        case ScanRoute::AutoHybrid:
        default: return "auto_hybrid";
    }
}

const char *PredictionEngine::styleName(PredictionStyle style) {
    switch (style) {
        case PredictionStyle::Simple: return "simple";
        case PredictionStyle::ProVideo: return "pro_video";
        case PredictionStyle::Advanced:
        default: return "advanced";
    }
}

std::vector<Point> PredictionEngine::pocketPoints(const Rect &table) {
    return {
        {table.x, table.y},
        {table.x + table.width * 0.5, table.y},
        {table.x + table.width, table.y},
        {table.x, table.y + table.height},
        {table.x + table.width * 0.5, table.y + table.height},
        {table.x + table.width, table.y + table.height}
    };
}

Point PredictionEngine::nearestPocket(const Point &point, const std::vector<Point> &pockets) {
    return *std::min_element(pockets.begin(), pockets.end(), [&](const Point &a, const Point &b) {
        return distance(point, a) < distance(point, b);
    });
}

Point PredictionEngine::pointToward(const Point &start, const Point &end, double d) {
    const double dx = end.x - start.x;
    const double dy = end.y - start.y;
    const double len = std::max(kEpsilon, std::hypot(dx, dy));
    return {start.x + dx / len * d, start.y + dy / len * d};
}

Point PredictionEngine::clamp(const Point &point, const Rect &rect) {
    return {
        std::min(std::max(point.x, rect.x), rect.x + rect.width),
        std::min(std::max(point.y, rect.y), rect.y + rect.height)
    };
}

double PredictionEngine::distance(const Point &a, const Point &b) {
    return std::hypot(a.x - b.x, a.y - b.y);
}

double PredictionEngine::cross(const Point &a, const Point &b) {
    return a.x * b.y - a.y * b.x;
}

Line PredictionEngine::makeLine(const Point &start, const Point &end, Color color, double width) {
    return {start, end, color, width};
}

Circle PredictionEngine::makeCircle(const Point &center, double radius, Color color, double width) {
    return {center, radius, color, width};
}

void PredictionEngine::addStyledLine(Result &result, const Point &start, const Point &end, Color color, double width, PredictionStyle style) {
    if (style == PredictionStyle::ProVideo) {
        result.lines.push_back(makeLine(start, end, Color{color.r, color.g, color.b, color.a * 0.20}, width * 3.1));
        result.lines.push_back(makeLine(start, end, Color{color.r, color.g, color.b, color.a * 0.34}, width * 1.85));
    }
    result.lines.push_back(makeLine(start, end, color, width));
}

std::vector<Point> PredictionEngine::bouncePath(const Point &start, const Point &target, const Rect &table, int count) {
    std::vector<Point> points;
    if (count <= 0) return points;
    points.push_back(start);

    Point current = start;
    double vx = target.x - start.x;
    double vy = target.y - start.y;
    const double len = std::max(kEpsilon, std::hypot(vx, vy));
    vx /= len;
    vy /= len;

    for (int i = 0; i < count; ++i) {
        const double tx = vx > 0 ? (table.x + table.width - current.x) / vx : (table.x - current.x) / vx;
        const double ty = vy > 0 ? (table.y + table.height - current.y) / vy : (table.y - current.y) / vy;
        const double t = std::max(kEpsilon, std::min(std::abs(tx), std::abs(ty)));
        Point next{current.x + vx * t, current.y + vy * t};
        points.push_back(next);

        if (std::abs(next.x - table.x) < 1.0 || std::abs(next.x - (table.x + table.width)) < 1.0) vx = -vx;
        if (std::abs(next.y - table.y) < 1.0 || std::abs(next.y - (table.y + table.height)) < 1.0) vy = -vy;
        current = next;
    }

    return points;
}

std::vector<Point> PredictionEngine::cueAfterHitPath(const ShotChoice &choice, const Rect &table, int count) {
    const Point incoming{choice.ghost.x - choice.cue.x, choice.ghost.y - choice.cue.y};
    const Point normal{choice.object.x - choice.ghost.x, choice.object.y - choice.ghost.y};
    const double nl = std::max(kEpsilon, std::hypot(normal.x, normal.y));
    const double nx = normal.x / nl;
    const double ny = normal.y / nl;
    const double dot = incoming.x * nx + incoming.y * ny;
    const Point tangent{incoming.x - dot * nx, incoming.y - dot * ny};
    const Point end{choice.ghost.x + tangent.x, choice.ghost.y + tangent.y};
    return bouncePath(choice.ghost, end, table, std::max(1, count));
}

std::vector<std::vector<Point>> PredictionEngine::bankGuides(const Point &object, const Point &pocket, const Rect &table) {
    std::vector<std::vector<Point>> guides;
    for (int rail = 0; rail < 4; ++rail) {
        std::vector<Point> guide;
        if (railGuide(object, pocket, table, rail, guide)) {
            guides.push_back(guide);
        }
    }
    std::sort(guides.begin(), guides.end(), [](const auto &a, const auto &b) {
        return guideLength(a) < guideLength(b);
    });
    if (guides.size() > 3) guides.resize(3);
    return guides;
}

bool PredictionEngine::railGuide(const Point &object, const Point &pocket, const Rect &table, int rail, std::vector<Point> &out) {
    Point mirror;
    if (rail == 0) mirror = {pocket.x, table.y * 2.0 - pocket.y};
    if (rail == 1) mirror = {pocket.x, (table.y + table.height) * 2.0 - pocket.y};
    if (rail == 2) mirror = {table.x * 2.0 - pocket.x, pocket.y};
    if (rail == 3) mirror = {(table.x + table.width) * 2.0 - pocket.x, pocket.y};

    const double dx = mirror.x - object.x;
    const double dy = mirror.y - object.y;
    double t = 0.0;
    if (rail == 0 || rail == 1) {
        if (std::abs(dy) <= kEpsilon) return false;
        t = ((rail == 0 ? table.y : table.y + table.height) - object.y) / dy;
    } else {
        if (std::abs(dx) <= kEpsilon) return false;
        t = ((rail == 2 ? table.x : table.x + table.width) - object.x) / dx;
    }
    if (t <= 0.05 || t >= 0.95) return false;
    const Point railPoint{object.x + dx * t, object.y + dy * t};
    if (railPoint.x < table.x - 2.0 || railPoint.x > table.x + table.width + 2.0 ||
        railPoint.y < table.y - 2.0 || railPoint.y > table.y + table.height + 2.0) {
        return false;
    }
    out = {object, railPoint, pocket};
    return true;
}

double PredictionEngine::guideLength(const std::vector<Point> &guide) {
    if (guide.size() != 3) return std::numeric_limits<double>::max();
    return distance(guide[0], guide[1]) + distance(guide[1], guide[2]);
}

PredictionEngine::ShotChoice PredictionEngine::chooseShot(const GameState &state, const Settings &settings, const std::vector<Point> &pockets) {
    const Point cue = state.hasCueBall ? state.cueBall : Point{state.table.x + state.table.width * 0.24, state.table.y + state.table.height * 0.5};
    ShotChoice best;
    best.score = std::numeric_limits<double>::max();

    const std::vector<int> pocketIndexes = settings.manualPocket
        ? std::vector<int>{std::max(0, std::min(settings.selectedPocket, static_cast<int>(pockets.size()) - 1))}
        : std::vector<int>{0, 1, 2, 3, 4, 5};

    for (const auto &ball : state.balls) {
        const double radius = ball.radius > 0.0 ? ball.radius : std::max(8.0, state.table.width * 0.018);
        if (ball.cue || distance(cue, ball.center) < radius * 2.5) continue;

        for (const int pocketIndex : pocketIndexes) {
            const Point pocket = pockets[pocketIndex];
            const double objectToPocket = std::max(kEpsilon, distance(ball.center, pocket));
            const double ux = (pocket.x - ball.center.x) / objectToPocket;
            const double uy = (pocket.y - ball.center.y) / objectToPocket;
            const Point ghost{ball.center.x - ux * radius * 2.0, ball.center.y - uy * radius * 2.0};
            const double cueToGhost = distance(cue, ghost);
            const Point a{ghost.x - cue.x, ghost.y - cue.y};
            const Point b{ball.center.x - cue.x, ball.center.y - cue.y};
            const double directness = std::abs(cross(a, b)) / std::max(1.0, cueToGhost);
            const double score = cueToGhost + objectToPocket * 0.62 + directness * 4.0;
            if (score < best.score) {
                best = {cue, ball.center, pocket, ghost, score, pocketIndex, radius};
            }
        }
    }

    if (best.score == std::numeric_limits<double>::max()) {
        best.ballRadius = 0.0;
    }
    return best;
}

} // namespace zg
