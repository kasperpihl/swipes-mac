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
@interface AppDelegate () <NSUserNotificationCenterDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (assign) IBOutlet WebView *webView;
@property WebViewJavascriptBridge *bridge;
@end

@implementation AppDelegate
@synthesize panelController = _panelController;
@synthesize menubarController = _menubarController;
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    self.bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"%@",data);
        if([data isKindOfClass:[NSDictionary class]]){
            NSString *sessionToken = [data objectForKey:@"sessionToken"];
            if(sessionToken){
                [[NSUserDefaults standardUserDefaults] setObject:sessionToken forKey:@"sessionToken"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
        responseCallback(@"Right back atcha");
    }];
    [self.bridge callHandler:@"register-notifications"];
    [self.bridge registerHandler:@"update-notification" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSDictionary *dictData = data;
        NSNumber *number = [dictData objectForKey:@"number"];
        NSString *badgeString = [number isEqualToNumber:@(0)] ? @"" : [number stringValue];
        [[[NSApplication sharedApplication] dockTile] setBadgeLabel:badgeString];
        
        NSArray *notifications = [dictData objectForKey:@"notifications"];
        [self handleNotifications:notifications];
        
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateWebview) name:@"refresh-webview" object:nil];
}
-(void)updateWebview{
    [self.bridge callHandler:@"refresh"];
}
-(void)webView:(WebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WebFrame *)frame{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:message];
    [alert runModal];
}
-(void)handleNotifications:(NSArray*)notifications{
    for( NSUserNotification *notification in [[NSUserNotificationCenter defaultUserNotificationCenter] scheduledNotifications]){
        [[NSUserNotificationCenter defaultUserNotificationCenter] removeScheduledNotification:notification];
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'"];

    NSDate *currentDate;
    NSDate *lastScheduledDate;
    //NSDate *schedDate = [[NSDate date] dateByAddingTimeInterval:4];
    for (NSDictionary *notifObject in notifications){
        NSString *title = [notifObject objectForKey:@"title"];
        NSString *identifier = [notifObject objectForKey:@"objectId"];
        NSString *dateString = [notifObject objectForKey:@"schedule"];
        NSDate *scheduleDate = [dateFormatter dateFromString:dateString];
        //scheduleDate = schedDate;
        NSNumber *priority = [notifObject objectForKey:@"priority"];
        BOOL isPriority = NO;
        if(priority && (id)priority != [NSNull null] && [priority integerValue] == 1){
            isPriority = YES;
        }
        
        if([scheduleDate isEqualToDate:currentDate]){
            if(lastScheduledDate){
                scheduleDate = [lastScheduledDate dateByAddingTimeInterval:2];
            }
        }
        else{
            currentDate = scheduleDate;
        }
        NSString *type = isPriority ? @"priority" : @"normal";
        [self scheduleNotificationForTime:scheduleDate withTitle:title informativeText:nil priority:isPriority userInfo:@{@"type":type,@"identifier":identifier}];
        lastScheduledDate = scheduleDate;
        
    }
    NSLog(@"%@",[[NSUserNotificationCenter defaultUserNotificationCenter] scheduledNotifications]);
}
-(void)scheduleNotificationForTime:(NSDate*)date withTitle:(NSString*)title informativeText:(NSString*)informativeText priority:(BOOL)priority userInfo:(NSDictionary*)userInfo{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = informativeText;
     notification.soundName = @"swipes-notification.aiff";
    if(priority){
        //notification.soundName = @"swipes-priority.aiff";
    }
    else{
        notification.soundName = @"swipes-notification.aiff";
    }
    notification.deliveryDate = date;
    notification.userInfo = userInfo;
    [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
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
    
    return NSAlertFirstButtonReturn == response;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification{
    NSLog(@"should present");
    return YES;
}
- (void) userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    NSLog(@"activate %@", [notification.userInfo objectForKey:@"identifier"]);
}

- (void) userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
    /*if([NSApplication sharedApplication].isActive){
        NSSound *notifSound = [NSSound soundNamed:@"swipes-priority.aiff"];
        [notifSound play];
    }*/
    NSLog(@"deliver %@",notification);
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
