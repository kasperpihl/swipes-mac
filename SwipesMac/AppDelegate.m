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
#import "AuthWindowController.h"
#import "SPHotKey.h"
#import "SPHotKeyManager.h"

//#ifdef DEBUG
//#define kWebAddress @"http://beta.swipesapp.com" //@"http://localhost:9000"
//#else
#define kWebAddress @"http://dev.swipesapp.com" //@"http://localhost:9000" //
//#endif
#define kLoginPath @"/signin"
#define kWebUrlRequest [NSURLRequest requestWithURL:[NSURL URLWithString:kWebAddress]]

@interface AppDelegate () <NSUserNotificationCenterDelegate, NSSharingServicePickerDelegate, AuthWindowControllerProtocol, WebUIDelegate, WebResourceLoadDelegate, WebPolicyDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (assign) IBOutlet WebView *webView;
@property (nonatomic, strong) AuthWindowController *authPopup;
@property WebViewJavascriptBridge *bridge;
@property (assign) BOOL shouldStartFBLogin;
@end

@implementation AppDelegate
@synthesize panelController = _panelController;
@synthesize menubarController = _menubarController;
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    [self.webView setGroupName:@"SwipesWeb"];
    
    
    //[WebViewJavascriptBridge enableLogging];
    [self.webView setUIDelegate:self];
    [self.webView setResourceLoadDelegate:self];
    [self.webView setPolicyDelegate:self];
    [self registerBridge];
    [self loadPage];
    
    
    
    [[[self.webView mainFrame] frameView] setAllowsScrolling:YES];
    
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dbPath = [paths objectAtIndex:0];
    WebPreferences* prefs = [self.webView preferences];
    NSString* localDBPath = [prefs _localStorageDatabasePath];
    
    // PATHS MUST MATCH!!!!  otherwise localstorage file is erased when starting program
    if( [localDBPath isEqualToString:dbPath] == NO) {
        [prefs setAutosaves:YES];  //SET PREFS AUTOSAVE FIRST otherwise settings aren't saved.
        // Define application cache quota
        static const unsigned long long defaultTotalQuota = 100 * 1024 * 1024; // 10MB
        static const unsigned long long defaultOriginQuota = 50 * 1024 * 1024; // 5MB
        [prefs setApplicationCacheTotalQuota:defaultTotalQuota];
        [prefs setApplicationCacheDefaultOriginQuota:defaultOriginQuota];
        
        [prefs setWebGLEnabled:YES];
        [prefs setOfflineWebApplicationCacheEnabled:YES];
        [prefs setJavaScriptEnabled:YES];
        [prefs setJavaScriptCanOpenWindowsAutomatically:YES];
        [prefs setDatabasesEnabled:YES];
        //[prefs setDeveloperExtrasEnabled:YES];
#ifdef DEBUG
        
#endif
        [prefs _setLocalStorageDatabasePath:dbPath];
        [prefs setLocalStorageEnabled:YES];
        [self.webView setPreferences:prefs];
    }
    //self.menubarController = [[MenubarController alloc] init];
    [self.window setContentView:self.webView];
    [self.window setTitle:@"Swipes"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateWebview) name:@"refresh-webview" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addTask:) name:@"add-task" object:nil];
    
    [self.window makeFirstResponder: self.webView];
    [self registerKeyboardHandler];
}
-(void)registerBridge{
    self.bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView webViewDelegate:self handler:^(id data, WVJBResponseCallback responseCallback) {
        if([data isKindOfClass:[NSDictionary class]]){
            NSString *sessionToken = [data objectForKey:@"sessionToken"];
            NSLog(@"session %@",sessionToken);
            if(sessionToken){
                [[NSUserDefaults standardUserDefaults] setObject:sessionToken forKey:@"sessionToken"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
        [self.bridge callHandler:@"register-notifications"];
        responseCallback(@"Right back atcha");
    }];
    [self.bridge registerHandler:@"update-notification" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSDictionary *dictData = data;
        NSNumber *number = [dictData objectForKey:@"number"];
        NSString *badgeString = [number isEqualToNumber:@(0)] ? @"" : [number stringValue];
        [[[NSApplication sharedApplication] dockTile] setBadgeLabel:badgeString];
        NSArray *notifications = [dictData objectForKey:@"notifications"];
        NSLog(@"here %@",dictData);
        [self handleNotifications:notifications];
        responseCallback(@"success");
    }];
    [self.bridge registerHandler:@"notify" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSDictionary *dictData = data;
        NSLog(@"%@",dictData);
        NSString *sound = @"swipes-message-sound.aiff";
        [self fireNotification:[dictData objectForKey:@"title"] message:[dictData objectForKey:@"message"] delivery:[dictData objectForKey:@"delivery"] sound:sound userInfo:[dictData objectForKey:@"userInfo"]];
    }];
}
-(void)loadPage{
    [[[self webView] mainFrame] loadRequest:kWebUrlRequest];
}
-(void)registerKeyboardHandler{
    SPHotKeyManager *hotKeyManager = [SPHotKeyManager instance];
    SPHotKey *hk = [[SPHotKey alloc] initWithTarget:self
                                    action:@selector(addToSwipes:)
                                   object:nil
                                  keyCode:kVK_ANSI_A
                            modifierFlags:(NSShiftKeyMask|NSCommandKeyMask)];
    
    [hotKeyManager registerHotKey:hk];
}

-(IBAction)openMenu:(id)sender{
    NSButton *senderButton = (NSButton*)sender;
    NSString *path = @"list/todo";
    [self openIfClosed];
    switch (senderButton.tag) {
        case 1:
            path = @"settings";
            break;
        case 2:
            path = @"list/scheduled";
            break;
        case 3:
            path = @"list/todo";
            break;
        case 4:
            path = @"list/completed";
            break;
        case 5:
            path = @"search";
            break;
        case 6:
            path = @"workspaces";
            break;
        case 7:
            path = @"add";
            break;
        case 8:
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://support.swipesapp.com"]];
            return;
        case 9:
            [self.bridge callHandler:@"intercom"];
            return;
        case 10:
            [self.bridge callHandler:@"trigger" data:@"show-keyboard-shortcuts"];
            return;
    }
    [self.bridge callHandler:@"navigate" data:path];
    
}
-(void)openIfClosed{
    [self.window makeKeyAndOrderFront:nil];
    [self.window makeFirstResponder: self.webView];
    [NSApp activateIgnoringOtherApps:YES];
    if(![self.window isKeyWindow]){
        
    }
}

-(IBAction)addToSwipes:(id)sender{
    [self togglePanel:self];
}
-(void)openAddSwipesWithEvent:(NSEvent *)hkEvent object:(AppDelegate*)appDelegate{
    [self.panelController openPanel];
}

-(void)addTask:(NSNotification*)notification{
    [self.bridge callHandler:@"add-task" data:notification.userInfo responseCallback:^(id responseData) {
        NSLog(@"response %@",responseData);
    }];
}
-(void)updateWebview{
    [self.bridge callHandler:@"refresh"];
}


-(void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame{

}

-(void)webView:(WebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WebFrame *)frame{
    if([message isEqualToString:@"something went wrong. Please try again."])
        return;
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:message];
    [alert runModal];
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
- (WebView *)webView:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request
{
    // HACK: This is all a hack to get around a bug/misfeature in Tiger's WebKit
    // (should be fixed in Leopard). On Javascript window.open, Tiger sends a null
    // request here, then sends a loadRequest: to the new WebView, which will
    // include a decidePolicyForNavigation (which is where we'll open our
    // external window). In Leopard, we should be getting the request here from
    // the start, and we should just be able to create a new window.
    
    WebView *newWebView = [[WebView alloc] init];
    [newWebView setUIDelegate:self];
    [newWebView setPolicyDelegate:self];
    return newWebView;
}

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {
    BOOL use = YES;
    BOOL open = YES;
    // Unset notifications and badge counter
    
    if([request.URL.absoluteString isEqualToString:[kWebAddress stringByAppendingString:kLoginPath]]){
        [[[NSApplication sharedApplication] dockTile] setBadgeLabel:@""];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"sessionToken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self handleNotifications:@[]];
    }
    if( [sender isEqual:self.webView] ) {
        
        if([request.URL.absoluteString hasPrefix:@"mailto:"]){
            use = NO;
        }
    }
    else{
        use = NO;
        NSLog(@"%@",request.URL.absoluteString);
    }
    
    if([request.URL.absoluteString hasPrefix:@"https://slack.com/oauth/authorize"]){
        //use = YES;
        open = NO;
        self.authPopup = [[AuthWindowController alloc] initWithWindowNibName:@"AuthWindowController"];
        self.authPopup.delegate = self;
        [self.authPopup showWindow:self.authPopup];
        NSLog(@"%@",request);
        [self.authPopup loadAuthWithURLRequest:request];
        [self.authPopup.window makeKeyWindow];
    }
    if([request.URL.absoluteString hasPrefix:@"https://www.facebook.com/dialog/oauth"]){
        use = YES;
    }
    if([request.URL.absoluteString hasPrefix:@"https://www.facebook.com/login.php"]){
        use = YES;
        NSLog(@"running login popup");
        
        self.authPopup = [[AuthWindowController alloc] initWithWindowNibName:@"AuthWindowController"];
        self.authPopup.delegate = self;
        [self.authPopup showWindow:self.authPopup];
        [self.authPopup loadAuthWithURLRequest:request];
        [self.authPopup.window makeKeyWindow];
    }
    
    
    if(use){
        [listener use];
    }
    else {
        if(open)
            [[NSWorkspace sharedWorkspace] openURL:[actionInformation objectForKey:WebActionOriginalURLKey]];
        [listener ignore];
    }
}

-(void)authController:(AuthWindowController *)authController didAuthWithURLRequest:(NSURLRequest *)urlRequest{
    NSString *javascriptString;
    if([urlRequest.URL.absoluteString hasPrefix:@"http://team.swipesapp.com/slacksuccess"]){
        NSMutableDictionary *queryStrings = [[NSMutableDictionary alloc] init];
        for (NSString *qs in [urlRequest.URL.query componentsSeparatedByString:@"&"]) {
            // Get the parameter name
            NSString *key = [[qs componentsSeparatedByString:@"="] objectAtIndex:0];
            // Get the parameter value
            NSString *value = [[qs componentsSeparatedByString:@"="] objectAtIndex:1];
            value = [value stringByReplacingOccurrencesOfString:@"+" withString:@" "];
            value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            queryStrings[key] = value;
        }
        NSLog(@"running %@",queryStrings);
        if(queryStrings[@"code"] && queryStrings[@"state"])
            javascriptString = [NSString stringWithFormat:@"window.loginView.handleSlackSuccess(\"%@\",\"%@\")",queryStrings[@"code"],queryStrings[@"state"]];
    }
    else{
        javascriptString = [NSString stringWithFormat:@"window.open(\"%@\")",urlRequest.URL.absoluteString];
    }
    NSLog(@"javascript %@",javascriptString);
    if(javascriptString)
        NSLog(@"%@",[self.webView stringByEvaluatingJavaScriptFromString:javascriptString]);
    //[[self.webView mainFrame] loadRequest:urlRequest];
    [authController close];
}

- (void)webView:(WebView *)sender decidePolicyForNewWindowAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request newFrameName:(NSString *)frameName decisionListener:(id<WebPolicyDecisionListener>)listener {
    NSLog(@"new frame");
    [[NSWorkspace sharedWorkspace] openURL:[actionInformation objectForKey:WebActionOriginalURLKey]];
    [listener ignore];
}
/*- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request
          frame:(WebFrame *)frame
decisionListener:(id<WebPolicyDecisionListener>)listener
{
    NSLog(@"%@",request.URL.absoluteString);
    if([request.URL.absoluteString hasPrefix:@"mailto:"] || [request.URL.absoluteString hasPrefix:@"https://twitter.com"])
    {
        [[NSWorkspace sharedWorkspace] openURL:request.URL];
        [listener ignore];
        return;
    }
}
 */
- (void)webView:(WebView *)sender runOpenPanelForFileButtonWithResultListener:(id < WebOpenPanelResultListener >)resultListener
{
    // Create the File Open Dialog class.
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    
    // Enable the selection of files in the dialog.
    [openDlg setCanChooseFiles:YES];
    
    // Enable the selection of directories in the dialog.
    [openDlg setCanChooseDirectories:NO];
    [openDlg beginWithCompletionHandler:^(NSInteger result) {
        if(result == NSFileHandlingPanelOKButton){
            NSArray* files = [[openDlg URLs]valueForKey:@"relativePath"];
            [resultListener chooseFilenames:files];
        }
        
    }];
    /*
    if ( [openDlg runModal] == NSOKButton )
    {
        NSArray* files = [[openDlg URLs]valueForKey:@"relativePath"];
        [resultListener chooseFilenames:files];
    }*/
    
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
    //NSLog(@"element: %@, defaults: %@", element[WebElementDOMNodeKey], defaultMenuItems);
    DOMHTMLElement* el = element[WebElementDOMNodeKey];
    if (el) {
        NSString* name = [el.nodeName lowercaseString];
        if ([name isEqualToString:@"input"] || [name isEqualToString:@"#text"] || [name isEqualToString:@"textarea"]) {
            return defaultMenuItems;
        }
    }
    //NSLog(@"element: %@", el.nodeName);
    return nil;
}

-(void)fireNotification:(NSString*)title message:(NSString*)message delivery:(NSDate*)delivery sound:(NSString*)sound userInfo:(NSDictionary*)userInfo{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = message;
    notification.soundName = @"swipes-notification.aiff";
    if(sound)
        notification.soundName = sound;
    notification.deliveryDate = [NSDate date];
    if(delivery)
        notification.deliveryDate = delivery;
    notification.userInfo = userInfo;
    NSLog(@"%@",notification);
    [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
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
}
-(void)scheduleNotificationForTime:(NSDate*)date withTitle:(NSString*)title informativeText:(NSString*)informativeText priority:(BOOL)priority userInfo:(NSDictionary*)userInfo{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = informativeText;
    notification.soundName = @"swipes-notification.aiff";
    notification.deliveryDate = date;
    notification.userInfo = userInfo;
    [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
}



-(IBAction)reloadWebview:(id)sender{
    [self loadPage];
    [self openIfClosed];
}


- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification{
    return YES;
}
- (void) userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    //NSLog(@"activate %@", [notification.userInfo objectForKey:@"identifier"]);
}

- (void) userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
    /*if([NSApplication sharedApplication].isActive){
        NSSound *notifSound = [NSSound soundNamed:@"swipes-priority.aiff"];
        [notifSound play];
    }*/
    //NSLog(@"deliver %@",notification);
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

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag{
    
    if( !flag ){
        [self openIfClosed];
    }
    return YES;
}
- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application
{
    return NO;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Explicitly remove the icon from the menu bar
    self.menubarController = nil;
    return NSTerminateNow;
}

#pragma mark - Actions
/*- (IBAction)performClose:(id)sender{
    NSLog(@"performing close");
}*/
- (void)togglePanel:(id)sender
{
    NSString *sessionToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"sessionToken"];
    if(sessionToken && sessionToken.length > 0){
        [self.window close];
        self.menubarController.hasActiveIcon = !self.menubarController.hasActiveIcon;
        self.panelController.hasActivePanel = self.menubarController.hasActiveIcon;
    }
    else{
        [self openIfClosed];
    }
}

#pragma mark - Public accessors
/*
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
*/
@end
