cmake_minimum_required(VERSION 3.25)
project(hyprtoolkit-demo CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(PkgConfig REQUIRED)
pkg_check_modules(HYPRTOOLKIT REQUIRED hyprtoolkit hyprutils hyprgraphics hyprlang aquamarine wayland-client wayland-protocols cairo pango pangocairo fontconfig expat libdrm libinput xkbcommon pixman-1)

add_executable(hyprtoolkit-demo main.cpp)

target_include_directories(hyprtoolkit-demo PRIVATE ${HYPRTOOLKIT_INCLUDE_DIRS})
target_link_libraries(hyprtoolkit-demo PRIVATE ${HYPRTOOLKIT_LIBRARIES})
