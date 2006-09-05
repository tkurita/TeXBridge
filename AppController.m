#import "AppController.h"
#import "CocoaLib/PaletteWindowController.h"
#import "CocoaLib/PathExtra.h"
#import "CocoaLib/WindowVisibilityController.h"
#import "DonationReminder/DonationReminder.h"

#import "NTYImmutableToMutableArrayOfObjectsTransformer.h"

//#import "AppNameToIconImageTransformer.h"

#define useLog 0
id EditorClient;
static id sharedObj;

@implementation AppController

+ (void)initialize	// Early initialization
{	
	NSValueTransformer *transformer = [[[NTYImmutableToMutableArrayOfObjectsTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"NTYImmutableToMutableArrayOfObjects"];
	
	sharedObj = nil;
	/*
	NSValueTransformer *appNameTransformer = [[[AppNameToIconImageTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:appNameTransformer forName:@"AppNameToIconImage"];
	 */
}

+ (id)sharedAppController
{
	if (sharedObj == nil) {
		sharedObj = [[self alloc] init];
	}
	return sharedObj;
}

- (id)init
{
	if (self = [super init]) {
		if (sharedObj == nil) {
			sharedObj = self;
		}
	}
	
	return self;
}

- (void)checkQuit:(NSTimer *)aTimer
{
	NSArray *appList = [[NSWorkspace sharedWorkspace] launchedApplications];
	NSEnumerator *enumerator = [appList objectEnumerator];
	
	id appDict;
	BOOL isMiLaunched = NO;
	while (appDict = [enumerator nextObject]) {
		NSString *appName = [appDict objectForKey:@"NSApplicationName"];
		if ([appName isEqualToString:@"mi"] ) {
			isMiLaunched = YES;
			break;
		}
	}
	
	if (! isMiLaunched) {
		[NSApp terminate:self];
	}
}

- (void)anApplicationIsTerminated:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"anApplicationIsTerminated");
#endif
	NSString *appName = [[aNotification userInfo] objectForKey:@"NSApplicationName"];
	if ([appName isEqualToString:@"mi"] ) [NSApp terminate:self];
}

- (void)revertToFactoryDefaultForKey:(NSString *)theKey
{
	id factorySetting = [factoryDefaults objectForKey:theKey];
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:factorySetting forKey:theKey];
}

- (id)factoryDefaultForKey:(NSString *)theKey
{
	return [factoryDefaults objectForKey:theKey];
}

- (int)judgeVisibilityForApp:(NSString *)appName
{
	/*
	 result = -1 : can't judge in this routine
	 0 : should hide	
	 1: should show
	 2: should not change
	 */
	 if ([appName isEqualToString:[EditorClient name]]) {
		 NSString *theMode;
		 @try{
			 theMode = [EditorClient currentDocumentMode];
		 }
		 @catch(NSException *exception){
			 NSNumber *err = [[exception userInfo] objectForKey:@"result code"];
			 if ([err intValue] == -1704) {
				 // maybe menu is opened
				 return 2;
			 }
			 else {
				 // maybe no documents opened
				 return 0;
			 }	
		 }
		 
		 if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"SupportedModes"]
				containsObject:theMode]) {
			 return 1;
		 } else {
			 return 0;
		 }
	 }
	return -1;
}

#pragma mark delegate of NSApplication
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationWillFinishLaunching");
#endif	
	/* regist FactorySettings into shared user defaults */
	NSString *defaultsPlistPath = [[NSBundle mainBundle] pathForResource:@"FactorySettings" ofType:@"plist"];
	factoryDefaults = [[NSDictionary dictionaryWithContentsOfFile:defaultsPlistPath] retain];
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults registerDefaults:factoryDefaults];
	
	/* checking checking UI Elements Scripting ... */
	if (!AXAPIEnabled())
    {
		[startupWindow close];
		[NSApp activateIgnoringOtherApps:YES];
		int ret = NSRunAlertPanel(NSLocalizedString(@"disableUIScripting", ""), @"", 
							NSLocalizedString(@"Launch System Preferences", ""),
							NSLocalizedString(@"Cancel",""), @"");
		switch (ret)
        {
            case NSAlertDefaultReturn:
                [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/UniversalAccessPref.prefPane"];
                break;
			default:
                break;
        }
        
		[NSApp terminate:self];
		return;
    }
	EditorClient = [[miClient alloc] init];
	WindowVisibilityController *wvController = [[WindowVisibilityController alloc] init];
	[wvController setDelegate:self];
	[wvController setUseTimer:YES];
	[PaletteWindowController setVisibilityController:[wvController autorelease]];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationDidFinishLaunching");
#endif
	appQuitTimer = [NSTimer scheduledTimerWithTimeInterval:60*60 target:self selector:@selector(checkQuit:) userInfo:nil repeats:YES];
	[appQuitTimer retain];
	
	NSNotificationCenter *notifyCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
	[notifyCenter addObserver:self selector:@selector(anApplicationIsTerminated:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];

	id reminderWindow = [DonationReminder remindDonation];
	if (reminderWindow != nil) [NSApp activateIgnoringOtherApps:YES];
}

@end
