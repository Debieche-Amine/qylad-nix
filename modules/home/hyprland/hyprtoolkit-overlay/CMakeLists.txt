cmake_minimum_required(VERSION 3.25)
project(hyprtoolkit-overlay CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(PkgConfig REQUIRED)
pkg_check_modules(HYPRTOOLKIT REQUIRED hyprtoolkit hyprutils hyprgraphics hyprlang aquamarine wayland-client wayland-protocols cairo pango pangocairo fontconfig expat libdrm libinput xkbcommon pixman-1)

add_executable(hyprtoolkit-overlay main.cpp)

target_include_directories(hyprtoolkit-overlay PRIVATE ${HYPRTOOLKIT_INCLUDE_DIRS})
target_link_libraries(hyprtoolkit-overlay PRIVATE ${HYPRTOOLKIT_LIBRARIES})
