//
//  AppDelegate.h
//  SwipesWrap
//
//  Created by Kasper Pihl Tornøe on 06/02/15.
//  Copyright (c) 2015 Kasper Pihl Tornøe. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "MenubarController.h"
#import "PanelController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, PanelControllerDelegate>
@property (nonatomic, strong) MenubarController *menubarController;
@property (nonatomic, strong, readonly) PanelController *panelController;

@end

