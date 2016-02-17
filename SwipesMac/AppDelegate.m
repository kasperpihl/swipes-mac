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
    
    [self.window makeFirstResponder: self.webView];
    [self registerKeyboardHandler];
}
-(void)registerBridge{
    self.bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView webViewDelegate:self handler:^(id data, WVJBResponseCallback responseCallback) {
        [self.bridge callHandler:@"register-notifications"];
        responseCallback(@"Right back atcha");
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
                                    action:@selector(openIfClosed)
                                   object:nil
                                  keyCode:kVK_ANSI_A
                            modifierFlags:(NSShiftKeyMask|NSCommandKeyMask)];
    
    [hotKeyManager registerHotKey:hk];
}

-(IBAction)openMenu:(id)sender{
    NSButton *senderButton = (NSButton*)sender;
    NSString *path = @"workspace";
    [self openIfClosed];
    switch (senderButton.tag) {
        case 1:
            path = @"settings";
            break;
        case 6:
            path = @"workspace";
            break;
        case 8:
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://support.swipesapp.com"]];
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
    WebView *newWebView = [[WebView alloc] init];
    [newWebView setUIDelegate:self];
    [newWebView setPolicyDelegate:self];
    return newWebView;
}

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {
    NSLog(@"%@", request.URL.absoluteString);
    BOOL use = YES;
    BOOL open = YES;
    // Unset notifications and badge counter
    
    if( [sender isEqual:self.webView] ) {
        
        if([request.URL.absoluteString hasPrefix:@"mailto:"]){
            use = NO;
        }
    }
    else{
        use = NO;
        NSLog(@"%@",request.URL.absoluteString);
    }
    
    // Make some general OAuth Handler ....
    if([request.URL.absoluteString hasPrefix:@"https://slack.com/oauth/authorize"] || [request.URL.absoluteString hasPrefix:@"https://swipes.atlassian.net/plugins/servlet/oauth/authorize"]){
        //use = YES;
        NSString *serviceName;
        if([request.URL.absoluteString hasPrefix:@"https://slack.com/oauth/authorize"])
            serviceName = @"slack";
        if([request.URL.absoluteString hasPrefix:@"https://swipes.atlassian.net/plugins/servlet/oauth/authorize"])
            serviceName = @"jira";
        open = NO;
        self.authPopup = [[AuthWindowController alloc] initWithWindowNibName:@"AuthWindowController"];
        self.authPopup.delegate = self;
        self.authPopup.serviceName = serviceName;
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
    if([urlRequest.URL.absoluteString hasPrefix:@"http://dev.swipesapp.com/oauth-success.html"]){
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
        
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:queryStrings
                                                           options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                             error:&error];
        
        if (!jsonData) {
            NSLog(@"Got an error: %@", error);
        } else {
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            NSLog(@"return from OAuth %@, %@",authController.serviceName, jsonString);
            javascriptString = [NSString stringWithFormat:@"window.OAuthHandler.onHandleAuthSuccess(\"%@\", \"%@\")", authController.serviceName, jsonString];
        }
        
    }
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




-(IBAction)reloadWebview:(id)sender{
    [self loadPage];
    [self openIfClosed];
}


- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification{
    return YES;
}

#pragma mark -

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
    return NSTerminateNow;
}

@end
