#include "flutter_window.h"

#include <optional>
#include <string>

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter_windows.h>

#include "flutter/generated_plugin_registrant.h"

// Window state constants
constexpr int kWindowActive = 1;
constexpr int kWindowInactive = 0;
constexpr int kWindowMinimized = 2;
constexpr int kWindowRestored = 3;

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case WM_ACTIVATE: {
      // Notify Flutter about window activation state changes.
      // LOWORD(wparam) == WA_INACTIVE (0) means window lost focus.
      if (flutter_controller_ && flutter_controller_->engine() &&
          flutter_controller_->engine()->messenger()) {
        bool isActive = LOWORD(wparam) != 0;
        uint8_t state = isActive ? kWindowActive : kWindowInactive;
        flutter_controller_->engine()->messenger()->Send(
            "com.example.nav_shell/window", &state, sizeof(state));
      }
      break;
    }
    case WM_SIZE: {
      // Detect window minimize/restore to pause/resume WebView2.
      // This is more reliable than WM_ACTIVATE for preventing click-blocking.
      if (flutter_controller_ && flutter_controller_->engine() &&
          flutter_controller_->engine()->messenger()) {
        uint8_t state;
        if (wparam == SIZE_MINIMIZED) {
          state = kWindowMinimized;
        } else if (wparam == SIZE_RESTORED || wparam == SIZE_MAXIMIZED) {
          state = kWindowRestored;
        } else {
          break;  // Ignore other size changes
        }
        flutter_controller_->engine()->messenger()->Send(
            "com.example.nav_shell/window", &state, sizeof(state));
      }
      break;
    }
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
