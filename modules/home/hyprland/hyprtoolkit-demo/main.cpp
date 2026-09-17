#include <hyprtoolkit/core/Backend.hpp>
#include <hyprtoolkit/window/Window.hpp>
#include <hyprtoolkit/element/Rectangle.hpp>
#include <hyprtoolkit/element/ColumnLayout.hpp>
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

    // 2. Build the main application window
    auto window = CWindowBuilder::begin()
        ->appTitle("Hyprtoolkit Demo")
        ->appClass("hyprtoolkit-demo")
        ->preferredSize({500, 320})
        ->commence();

    // Register close request listener (e.g. Super+Q, WM close button)
    window->m_events.closeRequest.listenStatic([backend]() {
        std::cout << "Close request received, exiting...\n";
        backend->destroy();
        std::exit(0);
    });

    // 3. Add a background rectangle using system theme colors
    auto background = CRectangleBuilder::begin()
        ->color([backend]() -> CHyprColor {
            return backend->getPalette()->m_colors.background;
        })
        ->size({CDynamicSize::HT_SIZE_PERCENT, CDynamicSize::HT_SIZE_PERCENT, {1.0f, 1.0f}})
        ->commence();
    window->m_rootElement->addChild(background);

    // 4. Create a vertical column layout
    auto layout = CColumnLayoutBuilder::begin()
        ->size({CDynamicSize::HT_SIZE_PERCENT, CDynamicSize::HT_SIZE_PERCENT, {1.0f, 1.0f}})
        ->commence();
    layout->setMargin(16);
    window->m_rootElement->addChild(layout);

    // 5. Add a Text Element
    auto label = CTextBuilder::begin()
        ->text("Welcome to Hyprtoolkit!")
        ->size({CDynamicSize::HT_SIZE_AUTO, CDynamicSize::HT_SIZE_AUTO, {1, 1}})
        ->commence();
    layout->addChild(label);

    int clickCount = 0;

    // 6. Add an interactive Counter Button
    auto button = CButtonBuilder::begin()
        ->label("Click Me (0)")
        ->size({CDynamicSize::HT_SIZE_AUTO, CDynamicSize::HT_SIZE_AUTO, {1, 1}})
        ->onMainClick([&clickCount](CSharedPointer<CButtonElement> btn) {
            clickCount++;
            std::cout << "Button clicked " << clickCount << " times!\n";
            btn->rebuild()->label("Click Me (" + std::to_string(clickCount) + ")")->commence();
        })
        ->commence();
    layout->addChild(button);

    // 7. Add an explicit Quit Button
    auto quitBtn = CButtonBuilder::begin()
        ->label("Quit Application")
        ->size({CDynamicSize::HT_SIZE_AUTO, CDynamicSize::HT_SIZE_AUTO, {1, 1}})
        ->onMainClick([backend](CSharedPointer<CButtonElement> btn) {
            std::cout << "Quit button clicked, exiting...\n";
            backend->destroy();
            std::exit(0);
        })
        ->commence();
    layout->addChild(quitBtn);

    // 8. Open/Map the window on screen
    window->open();

    // 9. Run the event loop
    backend->enterLoop();

    return 0;
}
