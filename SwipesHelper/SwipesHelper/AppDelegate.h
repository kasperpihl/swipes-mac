//
//  AppDelegate.h
//  SwipesHelper
//
//  Created by Kasper Pihl Tornøe on 18/02/15.
//  Copyright (c) 2015 Swipes ApS. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MenubarController.h"
#import "PanelController.h"
@interface AppDelegate : NSObject <NSApplicationDelegate, PanelControllerDelegate>
@property (nonatomic, strong) MenubarController *menubarController;
@property (nonatomic, strong, readonly) PanelController *panelController;

@end

