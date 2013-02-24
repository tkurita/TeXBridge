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

#define useLog 1
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
	if (texDoc.file) { // file is saved
		NSString *a_key = [texDoc pathWithoutSuffix];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"representedObject.pathWithoutSuffix LIKE %@", a_key];
		NSArray *filterd_array = [rootNode.childNodes filteredArrayUsingPredicate:predicate];
		if (filterd_array && [filterd_array count]) {
			result = [[filterd_array lastObject] representedObject];
			[result checkAuxFile];
		} else {
			result = [AuxFile auxFileWithTexDocument:texDoc];
		}
	} else { // file is not saved
		//ToDo : may require delete old unsavedAuxData
		self.unsavedAuxFile = [AuxFile auxFileWithTexDocument:texDoc];
	}
	
	return result;
}

- (AuxFile *)findAuxFileFromEditor
{
	NSError *error = nil;
	TeXDocument *tex_doc = [TeXDocument frontTexDocumentReturningError:&error];
	if (! tex_doc) return nil;
	
	if (tex_doc.file) {
		tex_doc = [tex_doc resolveMasterFromEditor];
	}
	
	return [self auxFileForDoc:tex_doc];
}

- (NSTreeNode *)appendToOutline:(AuxFile *)auxFile parentNode:(NSTreeNode *)parentNode
{
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
	return current_node;
}

- (void)expandChildrenIfNeeded:(NSTreeNode *)aNode
{	
	NSArray *pre_selected = [treeController selectionIndexPaths];
	[treeController setSelectionIndexPath:[aNode indexPath]];
	id row_item = [outlineView itemAtRow:[outlineView selectedRow]];
	if ([outlineView isItemExpanded:row_item]) {
		[outlineView expandItem:row_item expandChildren:YES];
	}
	[treeController setSelectionIndexPaths:pre_selected];
}

- (void)watchEditorWithReloading:(BOOL)reloading
{
	AuxFile *aux_file = [self findAuxFileFromEditor];
	if (! aux_file) {
		//ToDo: error processing
		return;
	}

	if ([aux_file hasTreeNode]) {
		BOOL from_aux_updated = NO;
		BOOL from_editor_updated = NO;
		if (reloading) {
			if ([aux_file checkAuxFile]) {
				[aux_file parseAuxFile];
			} else {
				[aux_file clearLabelsFromEditor];
			}
			from_aux_updated = YES;
		}
		
		if ([aux_file findLabelsFromEditorWithForceUpdate:reloading]) {
			from_editor_updated = YES;
		}
		
		if (from_aux_updated) {
			[aux_file updateChildren];
			[self expandChildrenIfNeeded:[aux_file treeNode]];
		} else if (from_editor_updated) {
			[aux_file updateLabelsFromEditor];
		}
		
	} else { // まだ ReferencePalette に登録されていない。
		if (aux_file.auxFilePath) {
			[aux_file parseAuxFile];
		}
		[aux_file findLabelsFromEditorWithForceUpdate:reloading];
		NSTreeNode *new_node = [self appendToOutline:aux_file parentNode:rootNode];		
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

static NSString *EQREF_COMMAND = @"\\eqref";

- (void)insertLabel:(id)sender
{
	NSArray  *selection = [treeController selectedObjects];
	id target_item = [[selection lastObject] representedObject];
	if ([target_item isKindOfClass:[AuxFile class]]) return;
	
	NSString *ref_name = [target_item referenceName];
	if (![ref_name length]) return;
	
	NSString *label_name = [target_item name];	
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
	[outlineView setDoubleAction:@selector(insertLabel:)];
	[outlineView setTarget:self];
}

@end
