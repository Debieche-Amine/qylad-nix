#include <hyprtoolkit/core/Backend.hpp>
#include <hyprtoolkit/window/Window.hpp>
#include <hyprtoolkit/element/Rectangle.hpp>
#include <hyprtoolkit/element/ColumnLayout.hpp>
#include <hyprtoolkit/element/RowLayout.hpp>
#include <hyprtoolkit/element/Text.hpp>
#include <hyprtoolkit/element/Button.hpp>
#include <hyprtoolkit/palette/Palette.hpp>
#include <iostream>
#include <cstdlib>

using namespace Hyprtoolkit;
using namespace Hyprutils::Memory;

int main(int argc, char** argv) {
    // 1. Initialize the Hyprtoolkit Wayland backend
    auto backend = IBackend::create();

    // 2. Build Layer Shell Overlay Window (SwayNC-style Right Sidebar Panel)
    auto window = CWindowBuilder::begin()
        ->type(HT_WINDOW_LAYER)
        ->appClass("hyprtoolkit-overlay")
        ->appTitle("Control Center Overlay")
        ->layer(3)          // Layer 3 = Overlay (renders above windows)
        ->anchor(1 | 2 | 8) // Anchor: Top (1) + Bottom (2) + Right (8)
        ->preferredSize({360, 0}) // 360px wide sidebar
        ->marginTopLeft({0, 10})
        ->marginBottomRight({10, 10})
        ->kbInteractive(1)
        ->commence();

    // Handle close signal (Super+Q / WM close)
    window->m_events.closeRequest.listenStatic([backend]() {
        std::cout << "Closing overlay...\n";
        backend->destroy();
        std::exit(0);
    });

    // 3. Background rectangle with rounded corners
    auto background = CRectangleBuilder::begin()
        ->color([backend]() -> CHyprColor {
            return backend->getPalette()->m_colors.background;
        })
        ->rounding(12)
        ->size({CDynamicSize::HT_SIZE_PERCENT, CDynamicSize::HT_SIZE_PERCENT, {1.0f, 1.0f}})
        ->commence();
    window->m_rootElement->addChild(background);

    // 4. Main Vertical Layout Container
    auto layout = CColumnLayoutBuilder::begin()
        ->size({CDynamicSize::HT_SIZE_PERCENT, CDynamicSize::HT_SIZE_PERCENT, {1.0f, 1.0f}})
        ->commence();
    layout->setMargin(20);
    window->m_rootElement->addChild(layout);

    // 5. Header Row (Title + Close Button)
    auto headerRow = CRowLayoutBuilder::begin()
        ->size({CDynamicSize::HT_SIZE_PERCENT, CDynamicSize::HT_SIZE_AUTO, {1.0f, 1.0f}})
        ->commence();

    auto title = CTextBuilder::begin()
        ->text("Control Center")
        ->size({CDynamicSize::HT_SIZE_AUTO, CDynamicSize::HT_SIZE_AUTO, {1, 1}})
        ->commence();
    headerRow->addChild(title);

    auto closeBtn = CButtonBuilder::begin()
        ->label(" Close ")
        ->size({CDynamicSize::HT_SIZE_AUTO, CDynamicSize::HT_SIZE_AUTO, {1, 1}})
        ->onMainClick([backend](CSharedPointer<CButtonElement> btn) {
            backend->destroy();
            std::exit(0);
        })
        ->commence();
    headerRow->addChild(closeBtn);

    layout->addChild(headerRow);

    // 6. Subtitle / Label
    auto label = CTextBuilder::begin()
        ->text("Quick Actions")
        ->size({CDynamicSize::HT_SIZE_AUTO, CDynamicSize::HT_SIZE_AUTO, {1, 1}})
        ->commence();
    layout->addChild(label);

    // 7. Interactive Toggle Buttons Row
    auto togglesRow = CRowLayoutBuilder::begin()
        ->size({CDynamicSize::HT_SIZE_PERCENT, CDynamicSize::HT_SIZE_AUTO, {1.0f, 1.0f}})
        ->commence();

    bool wifiOn = true;
    auto wifiBtn = CButtonBuilder::begin()
        ->label("Wi-Fi: ON")
        ->size({CDynamicSize::HT_SIZE_AUTO, CDynamicSize::HT_SIZE_AUTO, {1, 1}})
        ->onMainClick([&wifiOn](CSharedPointer<CButtonElement> btn) {
            wifiOn = !wifiOn;
            btn->rebuild()->label(wifiOn ? "Wi-Fi: ON" : "Wi-Fi: OFF")->commence();
        })
        ->commence();
    togglesRow->addChild(wifiBtn);

    bool dndOn = false;
    auto dndBtn = CButtonBuilder::begin()
        ->label("DND: OFF")
        ->size({CDynamicSize::HT_SIZE_AUTO, CDynamicSize::HT_SIZE_AUTO, {1, 1}})
        ->onMainClick([&dndOn](CSharedPointer<CButtonElement> btn) {
            dndOn = !dndOn;
            btn->rebuild()->label(dndOn ? "DND: ON" : "DND: OFF")->commence();
        })
        ->commence();
    togglesRow->addChild(dndBtn);

    layout->addChild(togglesRow);

    // 8. Open/Map the Layer Surface on Wayland
    window->open();

    // 9. Enter event loop
    backend->enterLoop();

    return 0;
}
