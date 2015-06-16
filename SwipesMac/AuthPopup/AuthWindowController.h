//
//  AuthWindowController.h
//  Swipes
//
//  Created by Kasper Pihl Tornøe on 16/06/15.
//  Copyright (c) 2015 Swipes ApS. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
@class AuthWindowController;
@protocol AuthWindowControllerProtocol <NSObject>

-(void)authController:(AuthWindowController*)authController didAuthWithURLRequest:(NSURLRequest*)urlRequest;

@end


@interface AuthWindowController : NSWindowController
-(void)loadAuthWithURLRequest:(NSURLRequest*)urlRequest;
@property (nonatomic, weak) NSObject<AuthWindowControllerProtocol> *delegate;
@end
