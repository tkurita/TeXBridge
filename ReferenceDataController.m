#import "ReferenceDataController.h"
#import "LabelDatum.h"
#import "TeXDocument.h"
#import "StringExtra.h"
#import "RegexKitLite.h"
#import "PathExtra.h"
//#import "mi.h"
#import "miClient.h"

#define useLog 1
@implementation ReferenceDataController

@synthesize contents;
@synthesize	rootNode;
@synthesize unsavedAuxFile;

- (void)dealloc
{
	[contents release];
	[super dealloc];
}

- (AuxFile *)auxFileForDoc:(TeXDocument *)texDoc
{
	AuxFile *result = nil;
	if (texDoc.file) { // file is saved
		NSString *a_key = [texDoc pathWithoutSuffix];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"representedObject.pathWithoutSuffix LIKE %@", a_key];
		//NSArray *filterd_array = [contents filteredArrayUsingPredicate:predicate];
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

- (BOOL)parseAuxFile:(AuxFile *)anAuxFile
{
	NSError *error = nil;
	NSString *aux_text = [anAuxFile readAuxFileReturningError:&error];
	// ToDo : error processing
	
	NSArray *paragraphs = [aux_text paragraphs];
	
	for (NSString *a_line in paragraphs) {
		NSLog(@"a line in aux : %@", a_line);
		// pickup newlabel commands
		NSArray *captures = [a_line captureComponentsMatchedByRegex:@"\\\\newlabel\\{([^{}]+)\\}\\{((\\{[^{}]*\\})+)\\}"];
		NSLog(@"%@", captures);
		if ([captures count] > 2) {
			NSString *label_name = [captures objectAtIndex:1];
			NSArray *second_captures = [[captures objectAtIndex:2] 
									  arrayOfCaptureComponentsMatchedByRegex:@"\\{([^{}]*)\\}"];
			NSLog(@"%@", second_captures);
			NSString *ref_name = nil;
			NSUInteger second_captures_count = [second_captures count];
			if ( second_captures_count > 3) { // hyperref
				ref_name = [[second_captures objectAtIndex:second_captures_count-2] lastObject];
			} else {
				ref_name = [[second_captures objectAtIndex:1] lastObject];
			}

			if ( [label_name length] || ![label_name hasPrefix:@"SC@"]) {
				[anAuxFile addLabelFromAux:label_name referenceName:ref_name];
			}
			continue;
		}
		// pickup input commands
		captures = [a_line captureComponentsMatchedByRegex:@"\\\\@input\\{([^{}]+)\\}"];
		NSLog(@"%@", captures);
		if ([captures count] > 1) {
			NSString *input_file = [captures objectAtIndex:1];
			NSURL *input_aux_url = [[NSURL URLWithString:input_file relativeToURL:[[anAuxFile texDocument] file]] 
							   absoluteURL];
#if useLog
			NSLog(@"%@", input_aux_url);
#endif			
			NSString *input_aux_path = [input_aux_url path];
			if ([input_aux_path fileExists]) {
				AuxFile *child_aux_file = [AuxFile auxFileWithPath:input_aux_path
													  textEncoding:anAuxFile.texDocument.textEncoding];
				if ([self parseAuxFile:child_aux_file]) {
					[anAuxFile addChildAuxFile:child_aux_file];
				}
				
			}
			continue;
		}
	}
	return YES;
}
/*
- (void)findLabelsFromEditor:(AuxFile *)anAuxFile forceUpdate:(BOOL)forceUpdate
{
	miClient *editor_client = [miClient sharedClient];
	NSString *content = [editor_client currentDocumentContent];
	if (! content) return;
	NSArray *paragraphs = [content paragraphs];
	if ((!forceUpdate) && (![anAuxFile isTexFileUpdated])) {
	
	}
	
	NSCharacterSet *spaces_set = [NSCharacterSet whitespaceCharacterSet];
	NSString *scaned_string;	
	for (NSString *a_line in paragraphs ) {
#if useLog
		NSLog(@"findLabelsFromEditor : %@", a_line);
#endif		
		a_line = [a_line stringByTrimmingCharactersInSet:spaces_set];		
		if (! [a_line length] ) continue;
		if ([a_line hasPrefix:@"%"]) continue;
		
		// remove comment
		NSScanner *scanner = [NSScanner scannerWithString:a_line];
		NSMutableString *clean_line = [NSMutableString stringWithCapacity:[a_line length]];
		while (![scanner isAtEnd]) {
			if ([scanner scanUpToString:@"%" intoString:&scaned_string]) {
				[clean_line appendString:scaned_string];
				if (! [scaned_string hasSuffix:@"\\"]) break;
				[clean_line appendString:@"%"];
				[scanner setScanLocation:[scanner scanLocation]+1];
			}
			NSLog(@"isAtEnd : %d, scan location : %d", [scanner isAtEnd], [scanner scanLocation]);
		}
		
		// find label command
		NSArray *captures = [clean_line arrayOfCaptureComponentsMatchedByRegex:@"\\\\label\\{([^{}]+)\\}"];
		if (! [captures count]) continue;
		for (NSArray *a_capture in captures) {
			NSString *label_name = [a_capture objectAtIndex:1];
			if (![anAuxFile hasLabel:label_name]) {
				[anAuxFile addLabelFromEditor:label_name];
			}
		}
		
		[anAuxFile updateCheckTime];
		anAuxFile.texDocumentSize = [content length];
#if useLog
		NSLog(@"%@", captures);
#endif		
		
	}
}
*/

- (void)setContents:(NSMutableArray *)newContents
{
	if (contents != newContents)
	{
		[contents release];
		contents = [[NSMutableArray alloc] initWithArray:newContents];
	}
}

- (void)appendToOutline:(AuxFile *)auxFile parentNode:(NSTreeNode *)parentNode
{
	NSTreeNode *current_node = [auxFile treeNode];
	if (parentNode) {
		[[parentNode mutableChildNodes] addObject:current_node];
	 } else {
		[treeController insertObject:current_node
		   atArrangedObjectIndexPath:[NSIndexPath indexPathWithIndex:[contents count]]];
		NSLog(@"current_node indexPath :%@", [current_node indexPath]);
	}
	
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
}

- (void)updateLabelsFromEditor:(AuxFile *)auxFile
{
	NSLog(@"start updateLabelsFromEditor");
	NSMutableArray *child_nodes = [[auxFile treeNode] mutableChildNodes];
	NSUInteger n_labels_from_editor = [auxFile.labelsFromEditor count];
	NSUInteger lab_count = 0;
	
	for (NSUInteger n=[auxFile.labelsFromAux count]; n < [child_nodes count]; n++) {
		if (lab_count < n_labels_from_editor) {
			[child_nodes replaceObjectAtIndex:n 
						   withObject:[[auxFile.labelsFromEditor objectAtIndex:lab_count] treeNode]];
		} else {
			[child_nodes removeObjectAtIndex:n];
		}
		lab_count++;
	}
	
	for (NSUInteger n=lab_count; n < n_labels_from_editor; n++) {
		[child_nodes addObject:[[auxFile.labelsFromEditor objectAtIndex:n] treeNode]];
	}
	
	NSLog(@"end updateLabelsFromEditor");
}

- (void)watchEditorWithReloading:(BOOL)reloading
{
	AuxFile *aux_file = [self findAuxFileFromEditor];
	if (! aux_file) {
		//ToDo: error processing
		return;
	}
	// aux file は tree node をもっているか？
	// もっていなかったら、tree node に展開して、contents に add する。
	// もっていなかったら、editor から label を取得する。
	if ([aux_file hasTreeNode]) {
		BOOL from_aux_updated = NO;
		BOOL from_editor_updated = NO;
		if (reloading) {
			
		}
		
		if ([aux_file findLabelsFromEditorWithForceUpdate:reloading]) {
			from_editor_updated = YES;
		}
		
		if (from_aux_updated) {
			
		} else if (from_editor_updated) {
			//[self updateLabelsFromEditor:aux_file];
			[aux_file updateLabelsFromEditor];
		}
		
	} else { // まだ ReferencePalette に登録されていない。
		if (aux_file.auxFilePath) {
			[self parseAuxFile:aux_file];
		}
		[aux_file findLabelsFromEditorWithForceUpdate:reloading];
		[self appendToOutline:aux_file parentNode:rootNode];
		id row_item = [outlineView itemAtRow:[outlineView selectedRow]];
		[outlineView expandItem:row_item expandChildren:YES];
	}
}

- (void)awakeFromNib
{
	NSMutableArray *array = [NSMutableArray array];
	/*
	[array addObject:[[LabelDatum labelDatumWithName:@"aaa" referenceName:@"bbb"] treeNode]];
	[array addObject:[[LabelDatum labelDatumWithName:@"ccc" referenceName:@"ddd"] treeNode]];
	 */
	self.contents = array;
	//[self watchEditorWithReloading:NO];
	self.rootNode = [NSTreeNode new];
}

@end
