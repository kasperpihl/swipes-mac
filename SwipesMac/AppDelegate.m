//
//  AppDelegate.m
//  SwipesWrap
//
//  Created by Kasper Pihl Tornøe on 06/02/15.
//  Copyright (c) 2015 Kasper Pihl Tornøe. All rights reserved.
//

#import "AppDelegate.h"
#import <WebKit/WebPreferences.h>
#import "WebStorageManagerPrivate.h"
#import "WebPreferencesPrivate.h"
#import "WebViewJavascriptBridge.h"
@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (assign) IBOutlet WebView *webView;
@property WebViewJavascriptBridge *bridge;
@end

@implementation AppDelegate
@synthesize panelController = _panelController;
@synthesize menubarController = _menubarController;
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    self.bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView handler:^(id data, WVJBResponseCallback responseCallback) {
        responseCallback(@"Right back atcha");
    }];
    
    [self.bridge registerHandler:@"update-notification" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSDictionary *dictData = data;
        NSNumber *number = [dictData objectForKey:@"number"];
        NSString *badgeString = [number isEqualToNumber:@(0)] ? @"" : [number stringValue];
        [[[NSApplication sharedApplication] dockTile] setBadgeLabel:badgeString];
        responseCallback(@"success");
    }];
    
    NSURL *url = [NSURL URLWithString:@"http://localhost:9000"];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    [[[self webView] mainFrame] loadRequest:urlRequest];
    [self.webView setUIDelegate:self];
    [[[self.webView mainFrame] frameView] setAllowsScrolling:YES];
    
    
    NSString* dbPath = [WebStorageManager _storageDirectoryPath];
    
    WebPreferences* prefs = [self.webView preferences];
    NSString* localDBPath = [prefs _localStorageDatabasePath];
    
    // PATHS MUST MATCH!!!!  otherwise localstorage file is erased when starting program
    if( [localDBPath isEqualToString:dbPath] == NO) {
        [prefs setAutosaves:YES];  //SET PREFS AUTOSAVE FIRST otherwise settings aren't saved.
        // Define application cache quota
        static const unsigned long long defaultTotalQuota = 10 * 1024 * 1024; // 10MB
        static const unsigned long long defaultOriginQuota = 5 * 1024 * 1024; // 5MB
        [prefs setApplicationCacheTotalQuota:defaultTotalQuota];
        [prefs setApplicationCacheDefaultOriginQuota:defaultOriginQuota];
        
        [prefs setWebGLEnabled:YES];
        [prefs setOfflineWebApplicationCacheEnabled:YES];
        [prefs setJavaScriptEnabled:YES];
        [prefs setJavaScriptCanOpenWindowsAutomatically:YES];
        [prefs setDatabasesEnabled:YES];
        [prefs setDeveloperExtrasEnabled:[[NSUserDefaults standardUserDefaults] boolForKey: @"developer"]];
#ifdef DEBUG
        [prefs setDeveloperExtrasEnabled:YES];
#endif
        [prefs _setLocalStorageDatabasePath:dbPath];
        [prefs setLocalStorageEnabled:YES];
        
        [self.webView setPreferences:prefs];
    }
    
    [self.window setContentView:self.webView];
    [self.window setTitle:@"Swipes"];
    self.menubarController = [[MenubarController alloc] init];
    
}
-(void)webView:(WebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WebFrame *)frame{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:message];
    [alert runModal];
}
-(void)fireNoti{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = @"Ohh no!";
    notification.informativeText = [NSString stringWithFormat:@"details details details"];
    notification.soundName = @"swipes-notification.aiff";
    notification.deliveryDate = [[NSDate date] dateByAddingTimeInterval:3];
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliveredNotifications];
}
- (BOOL)webView:(WebView *)sender runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WebFrame *)frame {
    /*
     NSWarningAlertStyle = 0,
     NSInformationalAlertStyle = 1,
     NSCriticalAlertStyle = 2
     */
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:message];
    NSModalResponse response = [alert runModal];
    [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(fireNoti) userInfo:nil repeats:NO];
    
    return NSAlertFirstButtonReturn == response;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}



- (void)dealloc
{
    [_panelController removeObserver:self forKeyPath:@"hasActivePanel"];
}

#pragma mark -

void *kContextActivePanel = &kContextActivePanel;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == kContextActivePanel) {
        self.menubarController.hasActiveIcon = self.panelController.hasActivePanel;
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}



- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Explicitly remove the icon from the menu bar
    self.menubarController = nil;
    return NSTerminateNow;
}

#pragma mark - Actions

- (IBAction)togglePanel:(id)sender
{
    self.menubarController.hasActiveIcon = !self.menubarController.hasActiveIcon;
    self.panelController.hasActivePanel = self.menubarController.hasActiveIcon;
}

#pragma mark - Public accessors

- (PanelController *)panelController
{
    if (_panelController == nil) {
        _panelController = [[PanelController alloc] initWithDelegate:self];
        [_panelController addObserver:self forKeyPath:@"hasActivePanel" options:0 context:kContextActivePanel];
    }
    return _panelController;
}

#pragma mark - PanelControllerDelegate

- (StatusItemView *)statusItemViewForPanelController:(PanelController *)controller
{
    return self.menubarController.statusItemView;
}

@end
