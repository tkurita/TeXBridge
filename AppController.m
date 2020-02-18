#import "AppController.h"
#import "PaletteWindowController.h"
#import "PathExtra.h"
#import "WindowVisibilityController.h"
#import "DonationReminder/DonationReminder.h"
#import "NSRunningApplication+SmartActivate.h"
#import "TeXDocument.h"
#import "NewRefPanelController.h"
#import "DVIPreviewModeTransformer.h"
#import "GUIScriptingChecker.h"

#import "LogParser.h"

#define useLog 0

id EditorClient;
static id sharedObj = nil;

NSArray *orderdEncodingCandidates(NSString *firstCandidateName)
{
	NSMutableArray *encoding_table = [[[NSUserDefaults standardUserDefaults] 
											arrayForKey:@"EncodingTable"] mutableCopy];
	if (firstCandidateName) {
		NSPredicate *a_predicate = [NSPredicate predicateWithFormat:@"name == %@", firstCandidateName];
		NSDictionary *first_candidate = [[encoding_table filteredArrayUsingPredicate:a_predicate] lastObject];
		[encoding_table removeObject:first_candidate];
		[encoding_table insertObject:first_candidate atIndex:0];
	}
	return [encoding_table valueForKey:@"id"];
}

@implementation AppController

+ (void)initialize	// Early initialization
{		
	if ([AppController class] == self) {
        sharedObj = nil;
		[NSValueTransformer setValueTransformer:[DVIPreviewModeTransformer new] forName:@"DVIPreviewModeTransformer"];
    }
}

+ (id)sharedAppController
{
	@synchronized(self) {
		if (sharedObj == nil) {
			(void) [[self alloc] init]; // ここでは代入していない
		}
	}
    return sharedObj;
}

+ (id)allocWithZone:(NSZone *)zone {  
    @synchronized(self) {  
        if (sharedObj == nil) {  
            sharedObj = [super allocWithZone:zone];  
            return sharedObj;  
        }  
    }  
    return nil;  
}  

- (id)copyWithZone:(NSZone*)zone {  
    return self;  // シングルトン状態を保持するため何もせず self を返す  
}  

- (void)checkQuit:(NSTimer *)aTimer
{
	if (![[NSRunningApplication runningApplicationsWithBundleIdentifier:@"net.mimikaki.mi"] count]) {
		[NSApp terminate:self];
	}
}

- (void)anApplicationIsTerminated:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"anApplicationIsTerminated");
#endif
	NSDictionary *user_info = [aNotification userInfo];
	NSString *identifier = user_info[@"NSApplicationBundleIdentifier"];
	if ([identifier isEqualToString:@"net.mimikaki.mi"] ) [[NSApplication sharedApplication] terminate:self];
	
}

- (void)revertToFactoryDefaultForKey:(NSString *)theKey
{
	id factorySetting = _factoryDefaults[theKey];
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:factorySetting forKey:theKey];
}

- (id)factoryDefaultForKey:(NSString *)theKey
{
	return _factoryDefaults[theKey];
}

- (int)judgeVisibilityForApp:(NSDictionary *)appDict
{
	/*
	result = -1 : can't judge in this routine
	0 : should hide	
	1: should show
	2: should not change
	*/
	if (! appDict) {
		return kShouldHide;
	}
	
	NSString *app_name = appDict[@"NSApplicationName"];

	if ([app_name isEqualToString:[EditorClient name]]) {
		NSString *theMode;
		@try{
			theMode = [EditorClient currentDocumentMode];
		}
		@catch(NSException *exception){
			#if useLog
			NSLog(@"%@", [exception description]);
			#endif
			 NSNumber *err = [exception userInfo][@"result code"];
			 if ([err intValue] == -1704) {
				 // maybe menu is opened
				 return kShouldNotChange;
			 }
			 else {
				 // maybe no documents opened
				 return kShouldHide;
			 }	
		 }
		 #if useLog
		 NSLog(@"current mode : %@", theMode);
		 #endif
		 
		 if (!theMode) {
			// may AESendMessage time outed
			return kShouldNotChange;
		 }
		 
		 if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"SupportedModes"]
				containsObject:theMode]) {
			 return kShouldShow;
		 } else {
			 return kShouldHide;
		 }
	 }
	return kShouldPostController;
}

- (void)setStartupMessage:(NSString *)message
{
	[startupMessageField setStringValue:message];
	[startupWindow displayIfNeeded];
}

#pragma mark actions for tool palette

- (IBAction)showSettingWindow:(id)sender
{
	if (!_settingWindow) {
		self.settingWindow = [[SettingWindowController alloc]
                              initWithWindowNibName:@"Setting"];
	}
	[_settingWindow showWindow:self];
	[NSRunningApplication activateSelf];
}

- (IBAction)quickTypesetPreview:(id)sender
{
    [_texBridgeController quickTypesetPreview];
}

- (IBAction)dviPreview:(id)sender
{
    [_texBridgeController dviPreview];
}

- (IBAction)dviToPDF:(id)sender
{
    [_texBridgeController dviToPDF];
}

- (IBAction)typesetPDFPreview:(id)sender
{
    [_texBridgeController typesetPDFPreview];
}

- (void)showStatusMessage:(NSString *)msg
{
	if (!_toolPaletteController) return;
	if (! [_toolPaletteController isOpened]) return;
	if ([_toolPaletteController isCollapsed]) return;
	[_toolPaletteController showStatusMessage:msg];
}

- (IBAction)showToolPalette:(id)sender
{
	if (!_toolPaletteController) {
		self.toolPaletteController = [[NewToolPaletteController alloc]
									initWithWindowNibName:@"NewToolPalette"];
	}
	[_toolPaletteController showWindow:self];
}

- (void)toggleToolPalette
{
	if (!_toolPaletteController) {
		return [self showToolPalette:self];
	}
	
	if ([_toolPaletteController isOpened]) {
		return [_toolPaletteController close];
	}
	
	[_toolPaletteController showWindow:self];
}

#pragma mark control for reference palette
- (void)stopTimer
{
	if (!_refPanelController) return;
	[_refPanelController temporaryStopReloadTimer];
}

- (void)restartTimer
{
	if (!_refPanelController) return;
	[_refPanelController restartReloadTimer];
}

- (void)rebuildLabelsFromAux:(NSString *)texFilePath textEncoding:(NSString *)encodingName
{
	if (!_refPanelController) return;
	if (![_refPanelController isOpened]) return;
	if ([_refPanelController isCollapsed]) return;
	[_refPanelController rebuildLabelsFromAux:texFilePath textEncoding:encodingName];
}

- (IBAction)showRefPalette:(id)sender
{
	if (!_refPanelController) {
		self.refPanelController = [[NewRefPanelController alloc]
								initWithWindowNibName:@"NewReferencePalette"];
	}
	[_refPanelController showWindow:self];
}

- (void)toggleRefPalette
{
	if (!_refPanelController) {
		return [self showRefPalette:self];
	}
	
	if ([_refPanelController isOpened]) {
		return [_refPanelController close];
	}
	
	[_refPanelController showWindow:self];
}

#pragma mark delegate of NSApplication
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationWillFinishLaunching");
#endif	
	/* regist FactorySettings into shared user defaults */
	NSString *defaultsPlistPath = [[NSBundle mainBundle] pathForResource:@"FactorySettings" 
																  ofType:@"plist"];
	self.factoryDefaults = [NSDictionary dictionaryWithContentsOfFile:defaultsPlistPath];
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults registerDefaults:_factoryDefaults];
    [userDefaults addSuiteNamed:@"TeXBridge"]; // to referer old settings
    if (! [GUIScriptingChecker check]) {
#if useLog		
		NSLog(@"%@", @"should quit because checkGUIScripting is disabled.");
#endif		
		[NSApp terminate:nil];
		return;
	}

	[startupWindow orderFront:self];
	EditorClient = [miClient sharedClient];
	WindowVisibilityController *wvController = [[WindowVisibilityController alloc] init];
	[wvController setDelegate:self];
	[wvController setFocusWatchApplication:@"net.mimikaki.mi"];
	[PaletteWindowController setVisibilityController:wvController];
	
	[_texBridgeController setup];
#if useLog
	NSLog(@"end applicationWillFinishLaunching");
#endif		
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationDidFinishLaunching");
#endif
	self.appQuitTimer = [NSTimer scheduledTimerWithTimeInterval:60*60 target:self
												  selector:@selector(checkQuit:) 
												  userInfo:nil repeats:YES];
	
	NSNotificationCenter *notifyCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
	[notifyCenter addObserver:self selector:@selector(anApplicationIsTerminated:) 
						 name:NSWorkspaceDidTerminateApplicationNotification object:nil];

	id reminderWindow = [DonationReminder remindDonation];
	if (reminderWindow != nil) [NSApp activateIgnoringOtherApps:YES];
	
	
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	
	self.toolPaletteController = nil;
	if ([user_defaults boolForKey:@"ShowToolPaletteWhenLaunched"] 
			||  [user_defaults boolForKey:@"IsOpenedToolPalette"]) {
		[self  setStartupMessage:@"Opening Tool Palette..."];
		[self showToolPalette:self];
	}
	
	self.refPanelController = nil;
	if ([user_defaults boolForKey:@"ShowRefPaletteWhenLaunched"] 
		||  [user_defaults boolForKey:@"IsOpenedRefPalette"]) {
		[self setStartupMessage:@"Opening Reference Palette..."];
		[self showRefPalette:self];
	}
	

	// Test Code
	/*
	NewRefPanelController *wc = [[NewRefPanelController alloc] initWithWindowNibName:@"NewReferencePalette"];
	[wc showWindow:self];
	 */
    
	[startupWindow close];
    
    /*
    LogParser *p = [[LogParser alloc] initWithContentsOfFile:@"/Users/tkurita/WorkSpace/Synchrotron/2019-03_RFK-Noise/平行電極間の荷電粒子が受ける仕事/charged-particle-in-parallel-electrode のコピー.log" encodingName: @"UTF-8"];
    //LogParser *p = [[LogParser alloc] initWithContentsOfFile:@"/Users/tkurita/WorkSpace/Synchrotron/2019-03_RFK-Noise/平行電極間の荷電粒子が受ける仕事/charged-particle-in-parallel-electrode.log" encodingName: @"UTF-8"];
    [p setBaseURLWithPath:@"/Users/tkurita/WorkSpace/Synchrotron/2019-03_RFK-Noise/平行電極間の荷電粒子が受ける仕事"];
    [p parseLog];
    */
    
#if useLog
	NSLog(@"end applicationDidFinishLaunching");
#endif	
}

@end
