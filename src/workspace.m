#include "workspace.h"
#include "buffer.h"
#include "event_tap.h"

void workspace_begin(void **context) {
    workspace_context *ws_context = [workspace_context alloc];
    *context = ws_context;

    [ws_context init];
}

bool workspace_check_frontmost_app_allowlist(void) {
    // Try to get the currently focused element using accessibility APIs
    AXUIElementRef focusedElement = NULL;
    AXUIElementRef systemWide = AXUIElementCreateSystemWide();
    
    if (AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute, (CFTypeRef*)&focusedElement) == kAXErrorSuccess && focusedElement) {
        
        // Get the application that owns this focused element
        AXUIElementRef focusedApp = NULL;
        if (AXUIElementCopyAttributeValue(focusedElement, kAXTopLevelUIElementAttribute, (CFTypeRef*)&focusedApp) == kAXErrorSuccess && focusedApp) {
            
            // Get the PID of the focused application
            pid_t pid = 0;
            if (AXUIElementGetPid(focusedApp, &pid) == kAXErrorSuccess) {
                
                // Get the application info
                NSRunningApplication *app = [NSRunningApplication runningApplicationWithProcessIdentifier:pid];
                if (app) {
                    char* app_name = (char*)[[app localizedName] UTF8String];
                    char* bundle_id = (char*)[[app bundleIdentifier] UTF8String];
                    
                    bool should_ignore = event_tap_check_allowlist(&g_event_tap, app_name, bundle_id);
                    
                    CFRelease(focusedApp);
                    CFRelease(focusedElement);
                    CFRelease(systemWide);
                    return should_ignore;
                }
            }
            CFRelease(focusedApp);
        }
        CFRelease(focusedElement);
    }
    CFRelease(systemWide);
    
    // Fallback to frontmost application
    NSRunningApplication *frontmostApp = [[NSWorkspace sharedWorkspace] frontmostApplication];
    
    if (!frontmostApp) {
        return true;
    }
    
    char* app_name = (char*)[[frontmostApp localizedName] UTF8String];
    char* bundle_id = (char*)[[frontmostApp bundleIdentifier] UTF8String];
    
    bool should_ignore = event_tap_check_allowlist(&g_event_tap, app_name, bundle_id);
    return should_ignore;
}

@implementation workspace_context
- (id)init {
    if ((self = [super init])) {
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                selector:@selector(appSwitched:)
                name:NSWorkspaceDidActivateApplicationNotification
                object:nil];
    }

    return self;
}

- (void)dealloc {
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)appSwitched:(NSNotification *)notification {
    char* name = NULL;
    char* bundle_id = NULL;
    pid_t pid = 0;
    if (notification && notification.userInfo) {
      NSRunningApplication* app = [notification.userInfo objectForKey:NSWorkspaceApplicationKey];
      if (app) {
        name = (char*)[[app localizedName] UTF8String];
        bundle_id = (char*)[[app bundleIdentifier] UTF8String];
        pid = app.processIdentifier;
      }
    }

    g_event_tap.front_app_ignored = event_tap_check_allowlist(&g_event_tap,
                                                              name,
                                                              bundle_id    );
    ax_front_app_changed(&g_ax, pid);
}

@end
