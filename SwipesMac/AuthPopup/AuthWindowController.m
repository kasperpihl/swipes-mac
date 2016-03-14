//
//  AuthWindowController.m
//  Swipes
//
//  Created by Kasper Pihl Tornøe on 16/06/15.
//  Copyright (c) 2015 Swipes ApS. All rights reserved.
//

#import "AuthWindowController.h"

@interface AuthWindowController () <WebPolicyDelegate>
@property (nonatomic, weak) IBOutlet WebView *webView;
@end

@implementation AuthWindowController
-(void)loadAuthWithURLRequest:(NSURLRequest *)urlRequest{
    //urlRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://facebook.com"]];
    [[self.webView mainFrame] loadRequest:urlRequest];
    [self.webView setGroupName:@"SwipesWeb"];
    
    [self.webView setPolicyDelegate:self];
}
- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {
    BOOL use = YES;
    BOOL open = YES;
    
    if([request.URL.absoluteString hasPrefix:@"http://dev.swipesapp.com/oauth-success.html"] || [request.URL.absoluteString hasPrefix:@"https://dev.swipesapp.com/oauth-success.html"]){
        use = NO;
        open = NO;
        [self.delegate authController:self didAuthWithURLRequest:request];
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

@end
