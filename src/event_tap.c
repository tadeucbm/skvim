#include "event_tap.h"

bool event_tap_check_allowlist(struct event_tap* event_tap,
                               char* app, char* bundle_id  ) {
  if (!app || !bundle_id) return true;
  for (int i = 0; i < event_tap->allowlist_count; i++)
    if (strcmp(event_tap->allowlist[i], app) == 0 
        || strcmp(event_tap->allowlist[i], bundle_id) == 0) {
      return false;
    }

  return true;
}

// Forward declaration of the workspace function
extern bool workspace_check_frontmost_app_allowlist(void);

static CGEventRef key_handler(CGEventTapProxy proxy, CGEventType type,
                              CGEventRef event, void* reference) {
  switch (type) {
    case kCGEventTapDisabledByTimeout:
      fprintf(stderr, "Timeout\n");
    case kCGEventTapDisabledByUserInput: {
      fprintf(stderr, "restarting event-tap\n");
      CGEventTapEnable(((struct event_tap*) reference)->handle, true);
    } break;
    case kCGEventKeyDown: {
      // Check the actual frontmost app in real-time for each key event
      bool app_should_be_ignored = workspace_check_frontmost_app_allowlist();
      
      if (app_should_be_ignored) {
        if (g_ax.selected_element && g_ax.role) {
          ax_clear(&g_ax);
        }
        return event;
      }

      return ax_process_event(&g_ax, event);
    } break;
  }
  return event;
}

bool event_tap_enabled(struct event_tap* event_tap) {
  bool result = (event_tap->handle && CGEventTapIsEnabled(event_tap->handle));
  return result;
}
void event_tap_load_allowlist(struct event_tap* event_tap) {
  event_tap->allowlist = NULL;
  event_tap->allowlist_count = 0;
  event_tap->front_app_ignored = true;

  char* home = getenv("HOME");
  char buf[512];
  snprintf( buf, sizeof(buf), "%s/%s", home, ".config/skvim/allowlist");

  FILE *file = fopen(buf, "r");

  if (!file) return;

  char line[255];
  while (fgets(line, 255, file)) {
    uint32_t len = strlen(line);
    if (line[len - 1] == '\n') line[len - 1] = '\0';
    event_tap->allowlist = realloc(event_tap->allowlist,
                                sizeof(char*) * ++event_tap->allowlist_count);

    event_tap->allowlist[event_tap->allowlist_count - 1] = string_copy(line);
  }

  fclose(file);
}

bool event_tap_begin(struct event_tap* event_tap) {
  event_tap_load_allowlist(event_tap);

  event_tap->mask = 1 << kCGEventKeyDown;
  event_tap->handle = CGEventTapCreate(kCGAnnotatedSessionEventTap,
                                       kCGHeadInsertEventTap,
                                       kCGEventTapOptionDefault,
                                       event_tap->mask,
                                       &key_handler,
                                       event_tap);

  bool result = event_tap_enabled(event_tap);
  if (result) {
    event_tap->runloop_source = CFMachPortCreateRunLoopSource(
                                                           kCFAllocatorDefault,
                                                           event_tap->handle,
                                                           0);
    CFRunLoopAddSource(CFRunLoopGetMain(),
                       event_tap->runloop_source,
                       kCFRunLoopCommonModes);
  }

  return result;
}

void event_tap_end(struct event_tap* event_tap) {
  if (event_tap_enabled(event_tap)) {
    CGEventTapEnable(event_tap->handle, false);
    CFMachPortInvalidate(event_tap->handle);
    CFRunLoopRemoveSource(CFRunLoopGetMain(),
                          event_tap->runloop_source,
                          kCFRunLoopCommonModes);
    CFRelease(event_tap->runloop_source);
    CFRelease(event_tap->handle);
    event_tap->handle = NULL;

    for (int i = 0; i < event_tap->allowlist_count; i++)
      if (event_tap->allowlist[i]) free(event_tap->allowlist[i]);

    if (event_tap->allowlist) free(event_tap->allowlist);
  }
}