#import <Carbon/Carbon.h>
#import "ReferenceDataController.h"
#import "LabelDatum.h"
#import "TeXDocument.h"
#import "StringExtra.h"
#import "RegexKitLite.h"
#import "PathExtra.h"
#import "miClient.h"
#import "ImageAndTextCell.h"
#import "mi.h"
#import "SmartActivate.h"
#import "miClient.h"


#define useLog 0
@implementation ReferenceDataController

@synthesize	rootNode;
@synthesize unsavedAuxFile;

- (void)dealloc
{
	[rootNode release];
	[super dealloc];
}

- (AuxFile *)auxFileForDoc:(TeXDocument *)texDoc
{
	AuxFile *result = nil;
	result = [AuxFile auxFileWithTexDocument:texDoc];
	if (! texDoc.file) {
		if (unsavedAuxFile) {
			[[rootNode mutableChildNodes] removeObject:[unsavedAuxFile treeNode]];
		}
		self.unsavedAuxFile = result;
	}
	return result;
}

- (AuxFile *)findAuxFileFromEditor
{
	NSError *error = nil;
	TeXDocument *tex_doc = [TeXDocument frontTexDocumentReturningError:&error];
	if (! tex_doc) return nil;
	return [self auxFileForDoc:tex_doc];
}

- (NSTreeNode *)appendToOutline:(AuxFile *)auxFile parentNode:(NSTreeNode *)parentNode
{
#if useLog
	NSLog(@"start appendToOutline");
#endif	
	NSTreeNode *current_node = [auxFile treeNode];
	[[parentNode mutableChildNodes] addObject:current_node];
	
	NSMutableArray *child_nodes = [current_node mutableChildNodes];
	NSArray *array_of_labels[] = {auxFile.labelsFromAux, auxFile.labelsFromEditor};
	
	for (int n = 0; n < 2; n++) {
		NSArray *labels = array_of_labels[n];
		for (id an_item in labels) {
			if ([an_item isKindOfClass:[AuxFile class]]) {
				[self appendToOutline:an_item parentNode:current_node];
			} else {
				NSTreeNode *a_node = [an_item treeNode];
				[child_nodes addObject:a_node];
			}

		}
	}
#if useLog
	NSLog(@"end appendToOutline");
#endif	
	return current_node;
}

- (id)rowItemForRepresentedObject:(id)anObject
{
	id result = nil;
	for (NSUInteger n=0; n<[outlineView numberOfRows]; n++) {
		id row_item = [outlineView itemAtRow:n];
		id rep_item = [[row_item representedObject] representedObject];
		if (rep_item == anObject) {
			result = row_item;
			goto bail;
		}
	}
bail:
	return result;
}

- (BOOL)rebuildLabelsFromAuxForDoc:(TeXDocument *)texDoc
{
	AuxFile *aux_file = [self auxFileForDoc:texDoc];
	if (![aux_file checkAuxFile]) return NO;
	if (![aux_file parseAuxFile]) return NO;
	
	[aux_file clearLabelsFromEditorRecursively:YES];
	[aux_file updateChildren];
	
	id row_item = [self rowItemForRepresentedObject:aux_file];
	[outlineView expandItem:row_item expandChildren:YES];

	return YES;
}

- (void)watchEditorWithReloading:(BOOL)reloading
{
#if useLog
	NSLog(@"start watchEditorWithReloading");
#endif	
	AuxFile *current_aux_file = [self findAuxFileFromEditor];
	if (! current_aux_file) {
		//ToDo: error processing
		return;
	}
	
	AuxFile *master_aux_file = current_aux_file;
	if (current_aux_file.texDocument.file) {
		TeXDocument *tex_doc = [[current_aux_file texDocument] 
										resolveMasterFromEditor];
		master_aux_file = [self auxFileForDoc:tex_doc];
	}
		
	if ([master_aux_file hasTreeNode]) {
		BOOL from_aux_updated = NO;
		BOOL from_editor_updated = NO;
		BOOL was_expanded;
		id row_item;

		if (reloading) {
			if ([master_aux_file checkAuxFile]) {
				row_item = [self rowItemForRepresentedObject:master_aux_file];
				was_expanded = [outlineView isItemExpanded:row_item];
				[master_aux_file parseAuxFile];
				from_aux_updated = YES;
			} else {
				row_item = [self rowItemForRepresentedObject:master_aux_file];
				was_expanded = [outlineView isItemExpanded:row_item];
				[current_aux_file clearLabelsFromEditor];
			}
		} else {
			row_item = [self rowItemForRepresentedObject:master_aux_file];
			was_expanded = [outlineView isItemExpanded:row_item];
		}

		
		if ([current_aux_file findLabelsFromEditorWithForceUpdate:reloading]) {
			from_editor_updated = YES;
		}
		
		if (from_aux_updated) {
			[master_aux_file updateChildren];
			//[self expandChildrenIfNeeded:[master_aux_file treeNode]];
		} else if (from_editor_updated) {
			[current_aux_file updateLabelsFromEditor];
		}
		if (was_expanded) {
			[outlineView expandItem:row_item expandChildren:YES];
		}
		
	} else { // まだ ReferencePalette に登録されていない。
		if (master_aux_file.auxFilePath) {
			[master_aux_file parseAuxFile];
		}
		[current_aux_file findLabelsFromEditorWithForceUpdate:reloading];
		NSTreeNode *new_node = [self appendToOutline:master_aux_file 
										  parentNode:rootNode];		
		NSArray *pre_selected = [treeController selectionIndexPaths];
		[treeController setSelectionIndexPath:[new_node indexPath]];
		id row_item = [outlineView itemAtRow:[outlineView selectedRow]];
		[outlineView expandItem:row_item expandChildren:YES];
		[treeController setSelectionIndexPaths:pre_selected];
	}
}

- (void)outlineView:(NSOutlineView *)olv willDisplayCell:(NSCell*)cell 
							forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if ([[tableColumn identifier] isEqualToString:@"label"]) {
		if ([cell isKindOfClass:[ImageAndTextCell class]]) {
			item = [item representedObject];
			[(ImageAndTextCell*)cell setImage:[[item representedObject] nodeIcon]];
		}
	}
}

void jumpToLabel(LabelDatum *targetLabel)
{
	AuxFile *aux_file = [[[targetLabel treeNode] parentNode] representedObject];
	NSURL *target_url = aux_file.texDocument.file;
	FSRef ref;
	CFURLGetFSRef((CFURLRef)target_url, &ref);
	NSString *label_command = [NSString stringWithFormat:@"\\label{%@}", targetLabel.name];

	miClient *mi_client = [miClient sharedClient];
	[mi_client jumpToFile:&ref paragraph:nil];
	NSString *doc_content = [mi_client currentDocumentContent];
	int n = -1; 
	for (NSString *a_line in [doc_content paragraphs]) {
		if ([a_line contain:label_command]) {
			n = n * -1;
			break;
		}
		n--;
	}
	if (n > 0) {
		[mi_client jumpToFile:&ref paragraph:[NSNumber numberWithInt:n]];
	}
	
}

static NSString *EQREF_COMMAND = @"\\eqref";

- (void)doubleAction:(id)sender
{
	
	NSArray  *selection = [treeController selectedObjects];
	id target_item = [[selection lastObject] representedObject];
	if ([target_item isKindOfClass:[AuxFile class]]) {
		FSRef fref;
		NSURL *file_url = ((AuxFile *)target_item).texDocument.file;
		CFURLGetFSRef((CFURLRef)file_url, &fref);
		[[miClient sharedClient] jumpToFile:&fref paragraph:nil];
		return;
	}
	
	NSString *ref_name = [target_item referenceName];	
	NSString *label_name = [target_item name];	
	if (![label_name length]) return;
	
	CGEventSourceStateID eventSource = kCGEventSourceStateCombinedSessionState;	
	bool is_command_down = CGEventSourceKeyState(eventSource, kVK_Control);
	if (is_command_down) {
		return jumpToLabel(target_item);
	}
	
	BOOL useeqref = [[NSUserDefaults standardUserDefaults] boolForKey:@"useeqref"];
	
	NSString *ref_command = @"\\ref";
	if (useeqref) {
		if ([ref_name hasPrefix:@"equation"] || [ref_name hasPrefix:@"AMS"]) {
			ref_command = EQREF_COMMAND;
		} else if ([ref_name isEqualToString:@"--"] && [label_name hasPrefix:@"eq"]) {
			ref_command = EQREF_COMMAND;
		}
	}
	
	miApplication *mi_app = [SBApplication applicationWithBundleIdentifier:@"net.mimikaki.mi"];
	miDocument *front_doc = [[mi_app documents] objectAtIndex:0];
	miSelectionObject *first_selection = [[front_doc selectionObjects] objectAtIndex:0];
	NSUInteger cursor_position = [[[first_selection insertionPoints] objectAtIndex:0] index];
	SBElementArray *paragraphs_in_selection = [first_selection elementArrayWithCode:'cpar'];
	miParagraph *first_paragraph_in_selection = [paragraphs_in_selection objectAtIndex:0];
	NSUInteger line_position = [[[first_paragraph_in_selection insertionPoints] objectAtIndex:0] index];
	NSUInteger position_in_line = cursor_position - line_position;
	
	NSString *text_before_cursor = @"";
	if (position_in_line > 0) {
		NSString *current_paragraph = [first_paragraph_in_selection content];
		text_before_cursor = [current_paragraph substringToIndex:position_in_line];
		if ([text_before_cursor hasSuffix:ref_command]) {
			[first_selection setContent:[NSString stringWithFormat:@"{%@}", label_name]];
			goto inserted;
		}
	} 
	[first_selection setContent: [NSString stringWithFormat:@"%@{%@}", ref_command, label_name]];
inserted:
	[SmartActivate activateAppOfIdentifier:@"net.mimikaki.mi"];
}

- (void)awakeFromNib
{
	NSTableColumn *table_column = [outlineView tableColumnWithIdentifier:@"label"];
	ImageAndTextCell *image_text_cell = [[ImageAndTextCell new] autorelease];
	[table_column setDataCell:image_text_cell];
	self.rootNode = [NSTreeNode new];
	[outlineView setDoubleAction:@selector(doubleAction:)];
	[outlineView setTarget:self];
}

@end
