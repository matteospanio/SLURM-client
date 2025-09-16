#include "my_application.h"

#ifdef GDK_WINDOWING_X11
#include <X11/Xlib.h>
#endif

int main(int argc, char** argv) {
#ifdef GDK_WINDOWING_X11
  // Initialize X11 threading support to fix XCB threading issues
  if (!XInitThreads()) {
    g_error("Failed to initialize X11 threading support");
    return 1;
  }
#endif

  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
