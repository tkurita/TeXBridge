#import "ReferenceDataController.h"
#import "LabelDatum.h"
#import "TeXDocument.h"
#import "StringExtra.h"
#import "RegexKitLite.h"
#import "PathExtra.h"
#import "miClient.h"

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

- (void)awakeFromNib
{
	self.rootNode = [NSTreeNode new];
}

@end
