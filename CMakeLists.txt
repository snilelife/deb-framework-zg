cmake_minimum_required(VERSION 3.20)
project(ZGPredictionOverlayKit LANGUAGES C CXX OBJCXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(ZG_OVERLAY_SOURCES
    src/ZGPredictionEngine.cpp
    src/ZGPredictionOverlayController.mm
    src/ZGPredictionOverlayAutoStart.mm
    bridges/ZGPredictionOverlayExports.mm
)

set(ZG_OVERLAY_PUBLIC_HEADERS
    include/ZGPredictionOverlayController.h
    include/ZGPredictionOverlayExports.h
    include/ZGPredictionEngine.hpp
    include/ZGOverlayTypes.hpp
)

function(zg_configure_overlay_target target_name constructor_enabled)
    target_include_directories(${target_name} PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/include
    )

    target_compile_options(${target_name} PRIVATE
        -fobjc-arc
    )

    target_compile_definitions(${target_name} PRIVATE
        ZG_PREDICTION_OVERLAY_ENABLE_CONSTRUCTOR=${constructor_enabled}
    )

    target_link_libraries(${target_name}
        "-framework Foundation"
        "-framework UIKit"
        "-framework QuartzCore"
        "-framework CoreGraphics"
    )
endfunction()

add_library(ZGPredictionOverlayKit SHARED ${ZG_OVERLAY_SOURCES})
zg_configure_overlay_target(ZGPredictionOverlayKit 0)

set_target_properties(ZGPredictionOverlayKit PROPERTIES
    FRAMEWORK TRUE
    FRAMEWORK_VERSION A
    MACOSX_FRAMEWORK_IDENTIFIER com.zg.predictionoverlaykit
    PUBLIC_HEADER "${ZG_OVERLAY_PUBLIC_HEADERS}"
)

add_library(ZGPredictionOverlayFramework SHARED ${ZG_OVERLAY_SOURCES})
zg_configure_overlay_target(ZGPredictionOverlayFramework 1)
set_target_properties(ZGPredictionOverlayFramework PROPERTIES
    OUTPUT_NAME ZGPredictionOverlay
    FRAMEWORK TRUE
    FRAMEWORK_VERSION A
    MACOSX_FRAMEWORK_IDENTIFIER com.zg.predictionoverlay.framework
    PUBLIC_HEADER "${ZG_OVERLAY_PUBLIC_HEADERS}"
)

add_library(ZGPredictionOverlay SHARED ${ZG_OVERLAY_SOURCES})
zg_configure_overlay_target(ZGPredictionOverlay 1)
set_target_properties(ZGPredictionOverlay PROPERTIES
    OUTPUT_NAME ZGPredictionOverlay
    INSTALL_NAME_DIR "@rpath"
    PUBLIC_HEADER "${ZG_OVERLAY_PUBLIC_HEADERS}"
)
