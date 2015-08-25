#import "NewRefPanelController.h"

#define useLog 0

extern id EditorClient;

@implementation NewRefPanelController


#pragma mark methods for the timer
- (void)periodicReload:(NSTimer *)theTimer
{
	if ([[self window] isVisible] && ![self isCollapsed]) {
		[dataController watchEditorWithReloading:NO];
	}
}

- (void)restartReloadTimer
{
	if (isWorkedReloadTimer) {
		[self setReloadTimer];
	}
}

- (void)temporaryStopReloadTimer
{
	if (reloadTimer != nil) {
		[reloadTimer invalidate];
		reloadTimer = nil;		
		isWorkedReloadTimer = YES;
	}
	else {
		isWorkedReloadTimer = NO;
	}
}

- (void)setReloadTimer
{
#if useLog
	NSLog(@"setReloadTimer");
#endif
	if (reloadTimer == nil) {
		reloadTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self 
													 selector:@selector(periodicReload:) 
													 userInfo:nil repeats:YES];
	} 
	else if (![reloadTimer isValid]) {
		[reloadTimer invalidate];
		reloadTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self 
													 selector:@selector(periodicReload:) 
													 userInfo:nil repeats:YES];
	}
}

#pragma mark actions
- (IBAction)showWindow:(id)sender
{
	[super showWindow:self];
	[self setReloadTimer];
}

- (IBAction)forceReload:(id)sender
{
	[dataController watchEditorWithReloading:YES];
}

#pragma mark delegete methods

- (void)awakeFromNib
{
	[self setFrameName:@"ReferencePalettePalette"];
	[self bindApplicationsFloatingOnForKey:@"ReferencePaletteApplicationsFloatingOn"];
	[self useFloating];
	[self useWindowCollapse];
	[dataController watchEditorWithReloading:NO];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationWillTerminate in NewRefPanelController");
#endif	
	[[NSUserDefaults standardUserDefaults] setBool:[self isOpened] 
											forKey:@"IsOpenedRefPalette"];
	[super applicationWillTerminate:aNotification];
}

- (BOOL)windowShouldClose:(id)sender
{
	if (reloadTimer != nil) {
		[reloadTimer invalidate];
		reloadTimer = nil;
	}
	[[NSUserDefaults standardUserDefaults] setBool:NO 
											forKey:@"IsOpenedRefPalette"];
	return [super windowShouldClose:sender];
}

//texFileFilePath must be master file.
- (void)rebuildLabelsFromAux:(NSString *)texFilePath textEncoding:(NSString *)encodingName
{
	TeXDocument *tex_doc = [TeXDocument texDocumentWithPath:texFilePath textEncoding:encodingName];
	[dataController rebuildLabelsFromAuxForDoc:tex_doc];
}
@end

