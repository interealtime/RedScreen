//
//  RedScreenAppDelegate.h
//  RedScreen
//
//  Created by Chris Wood on 29/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#define VERSION "2.0"
#define APPNAME "RedScreen"
#define AUTHOREMAIL "support@interealtime.com"
#define WEBSITE "http://interealtime.com/redscreen"

#import <Cocoa/Cocoa.h>

@interface RedScreenAppDelegate : NSObject {
	
    IBOutlet NSWindow *window, *startWindow;
	NSApplication *currentApp;
	
	IBOutlet NSMenu *statusMenu;
	IBOutlet NSMenuItem *activateItem;
	
	IBOutlet NSTextView *welcomeView;
	
	float redness, dimming, brightness;
	int ssHandling; // Screen saver type
	BOOL active, disableScreensaver, greyscale, inverted;

	NSTimer *ssdTimer;
	NSTimer *ssTimer;

	NSStatusItem *statusItem;

	CGDisplayFadeReservationToken token;
	CGDisplayCount displayCount;

	NSMutableArray *gammaValues;
	int gammaTypes[8];

	float displayBrightness;
	BOOL firstRun;

	BOOL ssEnabled, saveScreen;
}

-(int)ssHandling;
-(void)setSsHandling:(int)value;
-(float)redness;
-(void)setRedness:(float)value;
-(float)dimming;
-(void)setDimming:(float)value;
-(float)brightness;
-(void)setBrightness:(float)value;
-(BOOL)active;
-(void)setActive:(BOOL)value;
-(BOOL)disableScreensaver;
-(void)setDisableScreensaver:(BOOL)value;

-(void)setDisplayBrightness:(float)newBrightness;
-(void)setGreyscale:(BOOL)value;
-(void)setInverted:(BOOL)value;
-(BOOL)greyscale;
-(BOOL)inverted;

-(void)chooseNightVision:(id)sender;
-(void)chooseDarkMode:(id)sender;
-(void)saveDefaults:(id)sender;
-(BOOL)loadDefaults;
-(void)fireLoadDefaults:(id)sender;

-(void)hideWindow:(id)sender;
-(void)showWindow:(id)sender;
-(void)activate:(id)sender;

-(void)email:(id)sender;
-(void)openWeb:(id)sender;
-(void)reset:(id)sender;

@end
