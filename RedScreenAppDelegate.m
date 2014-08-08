//
//  RedScreenAppDelegate.m
//  RedScreen
//
//  Created by Chris Wood on 29/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "RedScreenAppDelegate.h"

#include <IOKit/graphics/IOGraphicsLib.h>
#include <ApplicationServices/ApplicationServices.h>

@implementation RedScreenAppDelegate

#pragma mark Support methods
/*
 Opens an email with the system default email app
 */
-(void)email:(id)sender{
	NSLog(@"Opening email to author");
	NSString *to = [NSString stringWithFormat:@"%s", AUTHOREMAIL];
	NSString *subject = [NSString stringWithFormat:@"%s %s", APPNAME, VERSION];
	NSString *encodedSubject = [NSString stringWithFormat:@"SUBJECT=%@", [subject stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
	NSString *encodedTo = [to stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
	NSString *encodedURLString = [NSString stringWithFormat:@"mailto:%@?%@", encodedTo, encodedSubject];
	NSURL *mailtoURL = [NSURL URLWithString:encodedURLString];
	[[NSWorkspace sharedWorkspace] openURL:mailtoURL];
}

	/*
	 Open the website
	 */
-(void)openWeb:(id)sender{
	NSLog(@"Opening website");
	NSString *site = [NSString stringWithFormat:@"%s", WEBSITE];
	NSString *encodedSite = [site stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
	NSURL *siteURL = [NSURL URLWithString:encodedSite];
	[[NSWorkspace sharedWorkspace] openURL:siteURL];
}

#pragma mark Settings load/save

-(void)saveDefaults:(id)sender{
	NSLog(@"Storing user defaults");
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:greyscale forKey:@"greyscale"];
	[defaults setBool:inverted forKey:@"inverted"];
	[defaults setInteger:ssHandling forKey:@"ssHandling"];
	[defaults setFloat:redness forKey:@"redness"];
	[defaults setFloat:dimming forKey:@"dimming"];
	[defaults setFloat:brightness forKey:@"brightness"];
	firstRun = NO;
}

	// used to load settings from UI, just passes message
-(void)fireLoadDefaults:(id)sender{
	[self loadDefaults];
}

-(BOOL)loadDefaults{
	NSLog(@"Attempting to load user defaults");
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	// see if defaults are set
	if(![defaults floatForKey:@"brightness"]) return NO;
	
	// defaults exist, load
	[self setGreyscale:[defaults boolForKey:@"greyscale"]];
	[self setInverted:[defaults boolForKey:@"inverted"]];
	[self setSsHandling:[defaults integerForKey:@"ssHandling"]];
	[self setRedness:[defaults floatForKey:@"redness"]];
	[self setDimming:[defaults floatForKey:@"dimming"]];
	[self setBrightness:[defaults floatForKey:@"brightness"]];

		// Mark as not first run for initial setup
	firstRun = NO;
	NSLog(@"Loaded Defaults");
	return YES;
}

	// Failsafe, removes settings and terminates app
-(void)reset:(id)sender{
	NSLog(@"Reseting user defaults");
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults removeObjectForKey:@"greyscale"];
	[defaults removeObjectForKey:@"inverted"];
	[defaults removeObjectForKey:@"ssHandling"];
	[defaults removeObjectForKey:@"redness"];
	[defaults removeObjectForKey:@"dimming"];
	[defaults removeObjectForKey:@"brightness"];
	[NSApp terminate:self];
}

#pragma mark Mode setting methods

	// Available on first run, sets settings for night vision (red)
-(void)chooseNightVision:(id)sender{
	NSLog(@"Setting Night Vision mode");
	[self setGreyscale:YES];
	[self setSsHandling:2];
	[self setRedness:1];
	[self setDimming:0.5];
	[self setBrightness:0.5];
	[startWindow close];
	[self saveDefaults:sender];
}

	// Available on first run, sets settings for dark use (non-red)
-(void)chooseDarkMode:(id)sender{
	NSLog(@"Setting Dark mode");
	[self setGreyscale:NO];
	[self setSsHandling:0];
	[self setRedness:0];
	[self setDimming:0.5];
	[self setBrightness:0.5];
	[startWindow close];
	[self saveDefaults:sender];
}

	// switches greyscale, updates display
-(void)setGreyscale:(BOOL)value{
	greyscale = value;
	if (active) [self setActive:active];
}

	// switches luminance inversion, updates display
-(void)setInverted:(BOOL)value{
	inverted = value;
	if (active) [self setActive:active];
}

-(BOOL)greyscale{
	return greyscale;
}

-(BOOL)inverted{
	return inverted;
}

	// returns screen saver mode
-(int)ssHandling{
	return ssHandling;
}

	// sets screen saver mode
-(void)setSsHandling:(int)value{
	ssHandling = value;
	switch (ssHandling) {
		case 0:
				// allow system screen saver
			NSLog(@"Ignoring Screensaver");
			ssEnabled = YES;
			saveScreen = NO;
			break;
		case 1:
				// prevent system screen saver
			NSLog(@"Disabling Screensaver");
			ssEnabled = NO;
			saveScreen = NO;
			break;
		case 2:
				// prevent system screen saver, replace it with interval fade
			NSLog(@"Replacing Screensaver");
			ssEnabled = NO;
			saveScreen = YES;
			break;
		default:
			break;
	}
		// update display
	if(active)[self setActive:active];
}

#pragma mark Machine wake handling

	// On wakeup, update display
- (void) receiveWakeNote: (NSNotification*) note{
    NSLog(@"receiveWakeNote: %@", [note name]);
	[self setActive:active];
}

#pragma mark Gamma handling

	// restores default gamma settings
- (void)restoreGamma {
	CGDisplayRestoreColorSyncSettings(); 
}

	// update gamma settings with current values
- (void)updateGamma {
	// Update gamma for each display

		// get display list
	CGDirectDisplayID displays[displayCount];
	CGDisplayErr cgErr;
	CGGetActiveDisplayList(displayCount, displays, NULL);
	
		// set gamma for each display
	for (int i = 0; i < [[NSScreen screens] count]; ++i) {
		switch (gammaTypes[i]) {
			case 0:{
					// set gamma by formula
				CGGammaValue rMin = [[[gammaValues objectAtIndex:i] objectAtIndex:0] floatValue];
				CGGammaValue rMax = [[[gammaValues objectAtIndex:i] objectAtIndex:1] floatValue];
				CGGammaValue rGamma = [[[gammaValues objectAtIndex:i] objectAtIndex:2] floatValue];
				CGGammaValue gMin = [[[gammaValues objectAtIndex:i] objectAtIndex:3] floatValue];
				CGGammaValue gMax = [[[gammaValues objectAtIndex:i] objectAtIndex:4] floatValue];
				CGGammaValue gGamma = [[[gammaValues objectAtIndex:i] objectAtIndex:5] floatValue];
				CGGammaValue bMin = [[[gammaValues objectAtIndex:i] objectAtIndex:6] floatValue];
				CGGammaValue bMax = [[[gammaValues objectAtIndex:i] objectAtIndex:7] floatValue];
				CGGammaValue bGamma = [[[gammaValues objectAtIndex:i] objectAtIndex:8] floatValue];
				// set new values
				CGGammaValue newRMax = rMax - dimming;
				newRMax = newRMax < rMin ? rMin : newRMax;
				CGGammaValue newGMax = (gMax - dimming) * (1 - redness);
				newGMax = newGMax < gMin ? gMin : newGMax;
				CGGammaValue newBMax = (bMax - dimming) * (1 - redness);
				newBMax = newBMax < bMin ? bMin : newBMax;
				
				NSLog(@"Set %d from %1.3f to %1.3f (dim: %1.3f)", i, gMax, newGMax, dimming);
				
				// set new transfer table
				cgErr = CGSetDisplayTransferByFormula(displays[i], rMin, newRMax, rGamma, gMin, newGMax, gGamma, bMin, newBMax, bGamma);
				if(cgErr) NSLog(@"Display transfer error: %d", cgErr);
				break;
			}
			case 1:{
					// fill tables with values
				NSLog(@"Setting Transfer tables directly. Min(%1.3f, %1.3f, %1.3f) max(%1.3f, %1.3f, %1.3f) mid(%1.3f, %1.3f, %1.3f)", 
					  [[[[gammaValues objectAtIndex:i] objectAtIndex:0] objectAtIndex:0] floatValue], 
					  [[[[gammaValues objectAtIndex:i] objectAtIndex:1] objectAtIndex:0] floatValue], 
					  [[[[gammaValues objectAtIndex:i] objectAtIndex:2] objectAtIndex:0] floatValue], 
					  [[[[gammaValues objectAtIndex:i] objectAtIndex:0] objectAtIndex:255] floatValue], 
					  [[[[gammaValues objectAtIndex:i] objectAtIndex:1] objectAtIndex:255] floatValue], 
					  [[[[gammaValues objectAtIndex:i] objectAtIndex:2] objectAtIndex:255] floatValue], 
					  [[[[gammaValues objectAtIndex:i] objectAtIndex:0] objectAtIndex:127] floatValue], 
					  [[[[gammaValues objectAtIndex:i] objectAtIndex:1] objectAtIndex:127] floatValue], 
					  [[[[gammaValues objectAtIndex:i] objectAtIndex:2] objectAtIndex:127] floatValue]);

					// create table arrays
				CGGammaValue redTable[ 256 ];
				CGGammaValue greenTable[ 256 ];
				CGGammaValue blueTable[ 256 ];
				CGDisplayErr cgErr;

					// set min/max values
				float minR = [[[[gammaValues objectAtIndex:i] objectAtIndex:0] objectAtIndex:0] floatValue];
				float minG = [[[[gammaValues objectAtIndex:i] objectAtIndex:1] objectAtIndex:0] floatValue];
				float minB = [[[[gammaValues objectAtIndex:i] objectAtIndex:2] objectAtIndex:0] floatValue];
				float maxR = [[[[gammaValues objectAtIndex:i] objectAtIndex:0] objectAtIndex:255] floatValue] * (1 - dimming);
				float maxG = [[[[gammaValues objectAtIndex:i] objectAtIndex:1] objectAtIndex:255] floatValue] * ((1 - dimming) * (1 - redness));
				float maxB = [[[[gammaValues objectAtIndex:i] objectAtIndex:2] objectAtIndex:255] floatValue] * ((1 - dimming) * (1 - redness));

					// fill tables
				for (int j = 0; j < 256 ; j++) {
					redTable[j] =  minR +  (maxR - minR) * [[[[gammaValues objectAtIndex:i] objectAtIndex:0] objectAtIndex:j] floatValue];
					greenTable[j] = minG + (maxG - minG) * [[[[gammaValues objectAtIndex:i] objectAtIndex:1] objectAtIndex:j] floatValue];
					blueTable[j] = minB + (maxB - minG) * [[[[gammaValues objectAtIndex:i] objectAtIndex:2] objectAtIndex:j] floatValue];
				}
		
				//get the list of displays
				CGDisplayCount numDisplays;
				CGGetActiveDisplayList(0, NULL, &numDisplays);
				CGGetActiveDisplayList(numDisplays, displays, NULL);
				
				// set the tables
				cgErr = CGSetDisplayTransferByTable(displays[i], 256, redTable, greenTable, blueTable);
				if(cgErr) NSLog(@"Set display transfer table failed. Error code: %d", cgErr);
				break;
			}
			default:
				break;
		}
	}
}

-(NSArray *)getGammaValue:(CGDirectDisplayID)display{
		// return array of display transfer tables (r,g,b)
	CGGammaValue gOriginalRedTable[ 256 ];
	CGGammaValue gOriginalGreenTable[ 256 ];
	CGGammaValue gOriginalBlueTable[ 256 ];
	UInt32 sampleCount;
	CGDisplayErr err;
	err = CGGetDisplayTransferByTable (display,
									   256,
									   gOriginalRedTable,
									   gOriginalGreenTable,
									   gOriginalBlueTable,
									   &sampleCount
									   );
	if (err) {
		NSLog(@"Failed to get display transfer by table. Error code: %d", err);
		return nil;
	}else {
		NSLog(@"Obtained display transfer by table.");
		NSMutableArray *rArray =[[NSMutableArray alloc] init];
		NSMutableArray *gArray =[[NSMutableArray alloc] init];
		NSMutableArray *bArray =[[NSMutableArray alloc] init];
		for(int i=0; i<256; i++){
			[rArray addObject:[NSNumber numberWithFloat:gOriginalRedTable[i]]];
			[gArray addObject:[NSNumber numberWithFloat:gOriginalGreenTable[i]]];
			[bArray addObject:[NSNumber numberWithFloat:gOriginalBlueTable[i]]];
		}
		return [NSArray arrayWithObjects:rArray, gArray, bArray, nil];
	}
}

	// update redness value, update gamma tables if needed
-(void)setRedness:(float)value{
	redness = value;
	if(active)[self updateGamma];
}

-(float)redness{
	return redness;
}

	// update dimming value, update gamma tables if needed
-(void)setDimming:(float)value{
	dimming = value;
	if(active)[self updateGamma];
}

-(float)dimming{
	return dimming;
}

#pragma mark Backlight handling

	// update backlight brightness, adjust hardware if needed
-(void)setBrightness:(float)value{
	brightness = value;
	if(active)[self setDisplayBrightness:brightness];
}

-(float)brightness{
	return brightness;
}

	// adjust hardware backlight brightness
- (void)setDisplayBrightness:(float)newBrightness {
	CGDisplayErr      dErr;
	io_service_t      service;
	CGDirectDisplayID targetDisplay;
	
	CFStringRef key = CFSTR(kIODisplayBrightnessKey);
	targetDisplay = CGMainDisplayID();
	service = CGDisplayIOServicePort(targetDisplay);
	
	if (newBrightness != HUGE_VALF)	dErr = IODisplaySetFloatParameter(service, kNilOptions, key, newBrightness);
}

	// get current backlight value
- (float)getDisplayBrightness {
	CGDisplayErr      dErr;
	io_service_t      service;
	CGDirectDisplayID targetDisplay;
	
	CFStringRef key = CFSTR(kIODisplayBrightnessKey);
	
	targetDisplay = CGMainDisplayID();
	service = CGDisplayIOServicePort(targetDisplay);
	
	float currentBrightness = 1.0;
	dErr = IODisplayGetFloatParameter(service, kNilOptions, key, &currentBrightness);
	displayBrightness = currentBrightness;
	[self setBrightness:displayBrightness];
	if (dErr == kIOReturnSuccess) {
		return currentBrightness;
	} else {
		return 1.0;
	}
}

#pragma mark RedScreen activation methods

	// turns display alterations on/off
-(void)setActive:(BOOL)value{
	active = value;
	NSLog(value ? @"Activated" : @"Deactivated");
	if (value) {
			// activate
		[self setDisplayBrightness:brightness];
		[self updateGamma];
		
		// set the bool values:
		CGDisplayForceToGray(greyscale);
		CGDisplaySetInvertedPolarity(inverted);

			// system screensaver prevention
		if(ssEnabled){
			[self setDisableScreensaver:NO];
		}else {
			[self setDisableScreensaver:YES];
		}

			// screensaver replacement
		if(saveScreen){
				// create a timer to trigger fade out
			if(![ssTimer isValid]) ssTimer = [[NSTimer scheduledTimerWithTimeInterval:1200 target:self selector:@selector(fadeOut:) userInfo:nil repeats:YES] retain];
		}else {
			if([ssTimer isValid]){
				[ssTimer invalidate];
				[ssTimer release];
				ssTimer = nil;
			} 
		}

	}else {
			// de-activate
		[self setDisplayBrightness:displayBrightness]; // default brightness
		[self restoreGamma];
		// set the bool values:
		CGDisplayForceToGray(NO);
		CGDisplaySetInvertedPolarity(NO);
			// kill screensaver disable/replace
		if([ssTimer isValid]){
			[ssTimer invalidate];
			[ssTimer release];
			ssTimer = nil;
		}
		[self setDisableScreensaver:NO];
	}

		// update button text
	[activateItem setTitle:active ? @"Deactivate RedScreen" : @"Activate RedScreen"];
}

-(BOOL)active{
	return active;
}

	// activation from UI
-(void)activate:(id)sender{
		// switch active
	active = !active;
	[self setActive:active];
		// update button
	[activateItem setTitle:active ? @"Deactivate RedScreen" : @"Activate RedScreen"];
}

#pragma mark Screensaver

	// fades out screen at interval as night safe screensaver replacement
-(void)fadeOut:(NSTimer *)timer{
	CGDisplayErr err;

		// reserve a token allowing us to fade the display
	err = CGAcquireDisplayFadeReservation (4.0, &token);
	if (err == kCGErrorSuccess)
	{
		err = CGDisplayFade (token, 1.0, kCGDisplayBlendNormal,
							 kCGDisplayBlendSolidColor, 0, 0, 0, true);
		err = CGDisplayFade (token, 1.0, kCGDisplayBlendSolidColor,
							 kCGDisplayBlendNormal, 0, 0, 0, true); 
		err = CGReleaseDisplayFadeReservation (token);
	}
}

	// fades screen back in after fadebout
-(void)fadeBack:(NSTimer *)timer{
	CGDisplayErr err;
	
	err = CGAcquireDisplayFadeReservation (1.0, &token);
	if (err == kCGErrorSuccess)
	{
		err = CGDisplayFade (token, 1.0, kCGDisplayBlendSolidColor,
							kCGDisplayBlendNormal, 0, 0, 0, true); 
		err = CGReleaseDisplayFadeReservation (token);
	}
}

	// disables system screensaver if needed
-(void)setDisableScreensaver:(BOOL)value{
	disableScreensaver = value;
	if(value){
			// disable screensaver by faking user input
		if(![ssdTimer isValid]){
			ssdTimer = [[NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(userActivityTimer:) userInfo:nil repeats:YES] retain];
		}
	}else {
			// enable screensaver
		[ssdTimer invalidate];
		[ssdTimer release];
		ssdTimer = nil;
	}
}

-(BOOL)disableScreensaver{
	return disableScreensaver;
}

	// fake user activity. Does nothing, but prevents screensaver from activating because the user 'did something'.
-(void)userActivityTimer:(NSTimer *)timer{
	UpdateSystemActivity(UsrActivity);
}

#pragma mark Application stuff

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	firstRun = YES;
	ssEnabled = NO;
	saveScreen = NO;
	
	gammaValues = [[NSMutableArray alloc] init];
	CGDisplayCount maxDisplays = 8;
	CGDirectDisplayID activeDisplays;
	CGGetActiveDisplayList(maxDisplays, &activeDisplays, &displayCount);
	
	// get original display tranfer data
	CGDirectDisplayID displays[displayCount];
	CGDisplayErr cgErr;
	CGGetActiveDisplayList(displayCount, displays, NULL);
	for (int i = 0; i < [[NSScreen screens] count]; ++i) {
		// get transfer table formula
		NSLog(@"Getting display transfer for display %d", i);
		CGGammaValue rMin, rMax, rGamma, gMin,gMax, gGamma, bMin, bMax, bGamma = 0;
		cgErr = CGGetDisplayTransferByFormula(displays[i], &rMin, &rMax, &rGamma, &gMin, &gMax, &gGamma, &bMin, &bMax, &bGamma);
		if (cgErr) {
			NSLog(@"Failed to get display transfer table by formula. Error code: %d. Attempting to get tables", cgErr);
			// attempt to obtain from table instead
			NSArray *values;
			if(values = [self getGammaValue:(CGDirectDisplayID)i]){
				// obtained tables
				[gammaValues insertObject:values atIndex:i];
				NSLog(@"Obtained Transfer tables directly. Min(%1.3f, %1.3f, %1.3f) max(%1.3f, %1.3f, %1.3f) mid(%1.3f, %1.3f, %1.3f)", 
					  [[[[gammaValues objectAtIndex:i] objectAtIndex:0] objectAtIndex:0] floatValue], 
					  [[[[gammaValues objectAtIndex:i] objectAtIndex:1] objectAtIndex:0] floatValue], 
					  [[[[gammaValues objectAtIndex:i] objectAtIndex:2] objectAtIndex:0] floatValue], 
					  [[[[gammaValues objectAtIndex:i] objectAtIndex:0] objectAtIndex:255] floatValue], 
					  [[[[gammaValues objectAtIndex:i] objectAtIndex:1] objectAtIndex:255] floatValue], 
					  [[[[gammaValues objectAtIndex:i] objectAtIndex:2] objectAtIndex:255] floatValue], 
					  [[[[gammaValues objectAtIndex:i] objectAtIndex:0] objectAtIndex:127] floatValue], 
					  [[[[gammaValues objectAtIndex:i] objectAtIndex:1] objectAtIndex:127] floatValue], 
					  [[[[gammaValues objectAtIndex:i] objectAtIndex:2] objectAtIndex:127] floatValue]);
				//values = nil;
				gammaTypes[i] = 1;
			}else {
				// failover. Use defaults...
				NSLog(@"Failed to obtain transfer by formula or table. Going to use defaults.");
				rMin = 0; rMax = 1; rGamma = 2.2;
				gMin = 0; gMax = 1; gGamma = 2.2;
				bMin = 0; bMax = 1; bGamma = 2.2;
				gammaTypes[i] = 0;
				[gammaValues insertObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:rMin], [NSNumber numberWithFloat:rMax], [NSNumber numberWithFloat:rGamma],
										[NSNumber numberWithFloat:gMin], [NSNumber numberWithFloat:gMax], [NSNumber numberWithFloat:gGamma], 
										   [NSNumber numberWithFloat:bMin], [NSNumber numberWithFloat:bMax], [NSNumber numberWithFloat:bGamma], nil] atIndex:i];
			}
		}else {
			// Gamma obtained from formula
			NSLog(@"Transfer obtained by formula. Min(%1.3f, %1.3f, %1.3f) max(%1.3f, %1.3f, %1.3f) gamma(%1.3f, %1.3f, %1.3f)", rMin, gMin, bMin, rMax, gMax, bMax, rGamma, gGamma, bGamma);
			gammaTypes[i] = 0;
			[gammaValues insertObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:rMin], [NSNumber numberWithFloat:rMax], [NSNumber numberWithFloat:rGamma],
								[NSNumber numberWithFloat:gMin], [NSNumber numberWithFloat:gMax], [NSNumber numberWithFloat:gGamma], 
								[NSNumber numberWithFloat:bMin], [NSNumber numberWithFloat:bMax], [NSNumber numberWithFloat:bGamma], nil] atIndex:i];
		}

	}
	
	// get screen brightness
	displayBrightness = [self getDisplayBrightness];
	// set up colours
	[self setRedness:1.0];
	[self setDimming:0.0];
	[self setSsHandling:0];
	[self setActive:NO];

	// create menu bar item
	NSImage *menuIcon = [NSImage imageNamed:@"StatusIcon.png"];
	NSStatusBar *bar = [NSStatusBar systemStatusBar];
	statusItem = [bar statusItemWithLength:NSVariableStatusItemLength];
	[statusItem retain];
	
	[statusItem setImage:(NSImage *) menuIcon];
	[statusItem setHighlightMode:YES];
	[statusItem setEnabled:YES];
	[statusItem setMenu:statusMenu];
	[statusItem setToolTip:@"RedScreen will continue running. You can access it from this menu!"];
	
	// register for app changes
	[[NSWorkspace sharedWorkspace] addObserver:self forKeyPath:@"runningApplications" options:nil context:nil];
	
	// see if first run and load defaults
	if([self loadDefaults]) {
		//[startWindow close];
	}else {
		[startWindow makeKeyAndOrderFront:nil];
	}
	
	// register for sleep state changes
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(receiveWakeNote:) name: NSWorkspaceDidWakeNotification object: NULL];
}

-(void)hideWindow:(id)sender{
	[window close];
//	[NSToolTipManager displayTooltip:[statusItem toolTip]];
//	[[statusMenu supermenu] ]
}

-(void)showWindow:(id)sender{
	[window makeKeyAndOrderFront:sender];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
//	NSLog(@"Observed %@", keyPath);
	[self setActive:active];
	NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timedActive:) userInfo:nil repeats:NO];
}

-(void)timedActive:(NSTimer *)timer{
//	NSLog(@"Timer fires...");
	[self setActive:active];
}

- (void)windowWillClose:(NSNotification *)notification{
	NSLog(@"window closed");
/*
	[self setDisplayBrightness:displayBrightness];
	
	CGDisplayForceToGray(NO);
	CGDisplaySetInvertedPolarity(NO);
	[NSApp terminate:self];
 */
}

- (void)applicationWillBecomeActive:(NSNotification *)aNotification{
	NSLog(@"RedScreen app activated");
	if(firstRun){[startWindow makeKeyAndOrderFront:nil];} else [window makeKeyAndOrderFront:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification{
	NSLog(@"RedScreen Terminating");
	[self setDisplayBrightness:displayBrightness];
	dimming = 0;
	redness = 0;
	[self updateGamma];
	CGDisplayForceToGray(NO);
	CGDisplaySetInvertedPolarity(NO);
	
}

@end
