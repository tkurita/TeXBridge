#import "LogParser.h"
#define useLog 0 //Yes:1, No:0

NSMutableDictionary * makeErrorRecord(NSString* errMsg, NSNumber* errpn) {
	NSMutableDictionary * dict = [NSMutableDictionary dictionary];
	[dict setObject:errMsg forKey:@"comment"];
	if (errpn !=nil) {
		[dict setObject:errpn forKey:@"paragraph"];
	}
	return dict;
}

NSMutableDictionary * makeLogRecord(NSString* logContents, unsigned int theNumber) {
	NSMutableDictionary * dict = [NSMutableDictionary dictionary];
	NSNumber * lineNumber = [NSNumber numberWithUnsignedInt:theNumber];
	[dict setObject:logContents forKey:@"content"];
	[dict setObject:lineNumber forKey:@"lineNumber"];
	return dict;
}

@implementation LogParser
- (BOOL) isDviOutput
{
	return self->isDviOutput;
}

- (BOOL) isLabelsChanged
{
	return self->isLabelsChanged;
}

- (id)init
{
	[super init];
	currentLineNumber = 0;
	newlineCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"\r\n"] retain];
	whitespaceCharSet = [[NSCharacterSet whitespaceCharacterSet] retain];
	isLabelsChanged = NO;
	errorRecordTree = [[NSMutableArray array] retain];
	texFileExtensions = [[NSArray arrayWithObjects:@".tex", @".cls", @".sty", @".aux", @".dtx", @".txt", @".bbl", @".ind",nil] retain];
	return self;
}

-(void)dealloc{
	[newlineCharacterSet release];
	[whitespaceCharSet release];
	[errorRecordTree release];
	[logFilePath release];
	[logContents release];
	[texFileExtensions release];
	[errorRecordTree release];
	[texFileExtensions release];
	[super dealloc];
}

- (id)initWithString:(NSString*)targetText
{
	[self init];
	isReadFile = NO;
	[self setLogFilePath:@""];
	[self setLogContents:targetText];
	int length = [logContents length];
	nextRange = NSMakeRange(0, length);
	return self;
}

- (id)initWithContentsOfFile:(NSString *)path
{
	[self init];
	[self setLogFilePath:path];
	isReadFile = YES;
	NSData *logData = [NSData dataWithContentsOfFile:logFilePath];
	[logContents release];
	[self setLogContents:[[[NSString alloc] initWithData:logData encoding:NSShiftJISStringEncoding] autorelease]];
	int length = [logContents length];
	nextRange = NSMakeRange(0, length);
	return self;
}

- (NSString *)getNextLine {
	NSRange subRange;
	
	if (nextRange.length > 0) {
		subRange = [logContents lineRangeForRange:NSMakeRange(nextRange.location, 0)];
		currentString = [logContents substringWithRange:subRange];
		currentRange = nextRange;
		nextRange.location = NSMaxRange(subRange);
        nextRange.length -= subRange.length;
		currentLineNumber++;
		
		if ([currentString length] == 1) {
			return [self getNextLine];
		} else {
			//NSLog(currentString);
			currentString = [currentString stringByTrimmingCharactersInSet:newlineCharacterSet];
			return currentString;
		}
	}
	else {
		return nil;
	}
}

- (void)addCurrentLine:(NSMutableArray*)currentList
{
	NSMutableDictionary * dict = makeLogRecord(currentString, currentLineNumber);
	[currentList addObject:dict];	
}

- (NSString *)addCurrentLineAndNextLine:(NSMutableArray *)currentList
{
	NSMutableDictionary * dict = makeLogRecord(currentString, currentLineNumber);
	[currentList addObject:dict];
	return [self getNextLine];
}

- (void) appendLogRecordWithString:(NSString *)targetText intoList:(NSMutableArray *)targetList {
	NSMutableDictionary * dict = makeLogRecord(targetText, currentLineNumber);
	[targetList addObject:dict];
}

- (NSMutableArray *) parseLog{
#if useLog
	NSLog(@"start parseLog");
#endif
	NSString * targetText = [self skipHeader];
	NSMutableDictionary * dict = makeLogRecord(targetText, currentLineNumber);
	NSMutableArray *logTree = [NSMutableArray arrayWithObject:dict];
	targetText = [self getNextLine];
	BOOL wholeLineFlag = YES;
#if useLog
	NSLog(@"before parseBodyWith");
#endif
	targetText = [self parseBodyWith:logTree startText:targetText isWholeLine:&wholeLineFlag];
	
	dict = makeLogRecord(logFilePath, 0);
	NSMutableArray *loglogTree = [NSMutableArray arrayWithObject:dict];
	[loglogTree addObject:logTree];
#if useLog
	NSLog(@"before parseFooterWith");
#endif
	[self parseFooterWith:loglogTree startText:targetText];
#if useLog
	NSLog([loglogTree description]);
#endif
	isDviOutput = YES;
	isLabelsChanged = NO;
	[self parseLogTreeFirstLevel:loglogTree];
	NSLog([errorRecordTree description]);
#if useLog
	NSLog(@"end of parseLog");
#endif
	return errorRecordTree;
}

- (NSString *) checkTexFileExtensions:(NSString *)targetFile
{
	NSEnumerator * suffixEnumerator = [texFileExtensions objectEnumerator];
	NSString * theSuffix;
	while (theSuffix = [suffixEnumerator nextObject]) {
		if ([targetFile endsWith:theSuffix]) {
			return targetFile;
		}
	}
	
	suffixEnumerator = [texFileExtensions objectEnumerator];
	while (theSuffix = [suffixEnumerator nextObject] ) {
		theSuffix = [theSuffix stringByAppendingString:@" "];
		NSRange theRange = [targetFile rangeOfString:theSuffix];
		if (theRange.length != 0) {
			return [targetFile substringWithRange:NSMakeRange(0,NSMaxRange(theRange)-1)];
		}
	}
	return nil;
}

- (NSString *) getTargetFilePath:(NSEnumerator *) enumerator
{

	NSString *targetFile = [[enumerator nextObject] objectForKey:@"content"];
	NSString *checkedPath;
	
	if (checkedPath = [self checkTexFileExtensions:targetFile]){
		return checkedPath;
	}
	
	if ([targetFile length] >= 79) {
		NSString * nextCandidate = [targetFile stringByAppendingString:[[enumerator nextObject] objectForKey:@"content"]];
		if (checkedPath = [self checkTexFileExtensions:nextCandidate]) {
			return checkedPath;
		}
		else{
			return nextCandidate;
		}
	}
	return targetFile;
}

- (void) parseLogTree:(NSMutableArray *) logTree
{
	//NSLog(@"start parseLogTree");
	if ([logTree count] <= 1) {
		return;
	}
	
	NSEnumerator *enumerator = [logTree objectEnumerator];
	//NSLog([logTree description]);
	NSString *targetFile = [self getTargetFilePath:enumerator];
	NSMutableDictionary * errorRecord;
	NSMutableArray *errorRecordList = [NSMutableArray array];
	id logItem;
	while (logItem = [enumerator nextObject]) {
		errorRecord = [self findErrors:logItem withEnumerator:enumerator];
		if (errorRecord) {
			[errorRecordList addObject:errorRecord];
		}
	}

	if ([errorRecordList count]) {
		NSMutableDictionary *errorRecordDict =
			[NSMutableDictionary dictionaryWithObject:errorRecordList forKey:@"errorRecordList"];
		[errorRecordDict setObject:targetFile forKey:@"file"];
		[errorRecordTree addObject:errorRecordDict];
	}
	//NSLog(@"end parseLogTree");
}

- (NSMutableDictionary *) findErrors:(id)logTree withEnumerator:(NSEnumerator *)enumerator
{
	//NSLog(@"start findErrors");
	NSString * logContent;
	
	if ([logTree isKindOfClass: [NSMutableArray class]]) {
		[self parseLogTree:logTree];
		return nil;
	}
	else {
		logContent = [logTree objectForKey:@"content"];
	}
	
	if ([logContent length] < 1) {
		return nil;
	}

	int errpInt;
	NSNumber * errpn = nil;
	id object;
	NSString * nextLogContent;
	NSMutableDictionary * errorRecord = nil;
	NSString * errMsg = nil;	
	if ([logContent startWith:@"!"]) {
		errMsg = [NSString stringWithString:logContent];
		isNoError = NO;
		while(object = [enumerator nextObject]) {
			if ([object isKindOfClass: [NSMutableDictionary class]]) {
				nextLogContent = [object objectForKey:@"content"];
			}
			else {
				nextLogContent = [[object objectAtIndex:0] objectForKey:@"content"];
			}
			
			if ([nextLogContent startWith:@"l."]) {
				NSScanner * scanner = [NSScanner scannerWithString:nextLogContent];
				NSString * scannedText;
				if ([scanner scanUpToCharactersFromSet:whitespaceCharSet intoString:&scannedText]) {
					errpInt =  [[scannedText substringWithRange:NSMakeRange(2,[scannedText length]-2)] intValue];
					errpn = [NSNumber numberWithInt:errpInt];
				}
				errorRecord = makeErrorRecord(errMsg,errpn);
				break;
			}
			else if ([nextLogContent startWith:@"?"] || [nextLogContent startWith:@"Enter file name:"]){
				errorRecord = makeErrorRecord(errMsg,errpn);
				break;
			}
		}
		
		if (errorRecord == nil) {
			errorRecord = makeErrorRecord(errMsg,errpn);
		}
	}
	else if ([logContent contain:@"Warning:"]) {
		errMsg = [NSString stringWithString:logContent];	
		if (![logContent endsWith:@"."]) {
			object = [enumerator nextObject];
			if ([object isKindOfClass: [NSMutableDictionary class]]) {
				errMsg = [logContent stringByAppendingString:[object objectForKey:@"content"]];
			}			
		}
		
		if ([errMsg contain:@"Label(s) may have changed. Rerun to get cross-references right."]) {
			isLabelsChanged = YES;
		}
		
		NSMutableArray *wordList = [errMsg splitWithCharacterSet:whitespaceCharSet];
		if ([[wordList objectAtIndex:([wordList count] -2)] isEqualToString:@"line"]) {
			errpInt = [[wordList lastObject] intValue];
			errpn = [NSNumber numberWithInt:errpInt];
		}
		errorRecord = makeErrorRecord(errMsg,errpn);
	}

	else if ([logContent startWith:@"Overfull"]||[logContent startWith:@"Underfull"]) {
		errMsg = [NSString stringWithString:logContent];
		NSMutableArray *wordList = [logContent splitWithCharacterSet:whitespaceCharSet];
		NSScanner *scanner = [NSScanner scannerWithString:[wordList lastObject]];
		if ([scanner scanInt:&errpInt]) {
			errpn = [NSNumber numberWithInt:errpInt];	
		}
	}
	
	else if ([logContent startWith:@"No file"]) {
		errMsg = [NSString stringWithString:logContent];
		isNoError = NO;
	}
	
	else if ([logContent isEqualToString:@"No pages of output."]) {
		errMsg = [NSString stringWithString:logContent];
		isNoError = NO;
		isDviOutput = NO;
	}
	
	//NSLog(@"end of findErrors");
	
	if (errMsg != nil) {
		return makeErrorRecord(errMsg,errpn);
	}
	else {
		return nil;
	}
}

- (void) parseLogTreeFirstLevel:(NSMutableArray *)logTree
{
	NSEnumerator *enumerator = [logTree objectEnumerator];
	NSString * targetFile = [[enumerator nextObject] objectForKey:@"content"];
	NSMutableDictionary * errorRecord;
	NSMutableArray * errorRecordList = [NSMutableArray array];
	
	id logItem;
	while (logItem = [enumerator nextObject]) {
		errorRecord = [self findErrors:logItem withEnumerator:enumerator];
		if (errorRecord) {
			[errorRecord setObject:[logItem objectForKey:@"lineNumber"] forKey:@"paragraph"];
			[errorRecordList addObject:errorRecord];
		}
	}
	if ([errorRecordList count]) {
		NSMutableDictionary * errorRecordDict =
			[NSMutableDictionary dictionaryWithObject:errorRecordList forKey:@"errorRecordList"];
		[errorRecordDict setObject:targetFile forKey:@"file"];
		[errorRecordTree addObject:errorRecordDict];
	}
}

-(void) parseFooterWith:(NSMutableArray *)currentList startText:(NSString *)targetText 
{
	while(targetText != nil) {
		targetText = [self addCurrentLineAndNextLine:currentList];
	}
}

- (NSString *) parseLines:(NSString *)targetText withList:(NSMutableArray *)currentList {
#if useLog
	NSLog(@"start parseLines");
#endif
	if (targetText == nil) return nil;
#if useLog
	NSLog(targetText);
#endif
	if ([targetText startWith:@"LaTeX Font Info:"] 
			||[targetText startWith:@"Latex Info"]
			||[targetText startWith:@"\\"]) {
		//skip this line
		return [self parseLines:[self getNextLine] withList:currentList];
		
	} else if ([targetText startWith:@"LaTeX Font"]
			   ||[targetText startWith:@"(FONT)"]
			   ||[targetText startWith:@"Package hyperref"]
			   ||[targetText startWith:@"(hyperref)"]) {
			  // ||[targetText startWith:@"Package:"]) {
		//just add this line into currentList
		return [self parseLines:[self addCurrentLineAndNextLine:currentList] withList:currentList];
		
	} else if ([targetText contain:@"Warning:"]){
		unsigned int theCurrentLineNumber = currentLineNumber;
		while (! [targetText endsWith:@"."]) {
			targetText = [targetText stringByAppendingString:[self getNextLine]];
		}
		NSMutableDictionary * dict = makeLogRecord(targetText, theCurrentLineNumber);
		[currentList addObject:dict];
		return [self parseLines:[self getNextLine] withList:currentList];
	
	} else if ([targetText startWith:@"Overfull"]) {
		//targetText = [self addCurrentLineAndNextLine:currentList];
		[self addCurrentLine:currentList];
		if (isReadFile) {
			while (! ([targetText endsWith:@"[]"]||[targetText endsWith:@"[] "])) {
				targetText = [self getNextLine];
			}
		}
		return [self parseLines:[self getNextLine] withList:currentList];

	} else if ([targetText startWith:@"Underfull"]) {
		return [self parseLines:[self addCurrentLineAndNextLine:currentList] withList:currentList];

	} else if ([targetText startWith:@"Runaway argument?"]) {
		targetText = [self addCurrentLineAndNextLine:currentList];
		while (! [targetText startWith:@"!"]) {
			targetText = [self addCurrentLineAndNextLine:currentList];
		}
		return [self parseLines:[self addCurrentLineAndNextLine:currentList] withList:currentList];

	} else if ([targetText startWith:@"l."]) {
		targetText = [self addCurrentLineAndNextLine:currentList];
		while ([targetText startWith:@" "]) {
			targetText = [self addCurrentLineAndNextLine:currentList];
		}
		//return [self parseLines:[self addCurrentLineAndNextLine:currentList] withList:currentList];
		return [self parseLines:targetText withList:currentList];

	} else if ([targetText startWith:@"!"]) {
		unsigned int theCurrentLineNumber = currentLineNumber;
		if ([targetText length] >= 79) {
			//add two lines into current list
			targetText = [targetText stringByAppendingString:[self getNextLine]];
		}
		NSMutableDictionary * dict = makeLogRecord(targetText, theCurrentLineNumber);
		[currentList addObject:dict];
		return [self parseLines:[self getNextLine] withList:currentList];
		
	} else {
#if useLog
		NSLog(@"back to parseBody");
#endif
		return targetText;
	}
}

- (NSString *) parseBodyWith:(NSMutableArray *)currentList startText:(NSString *)targetText isWholeLine:(BOOL *)wholeLineFlag {
#if useLog
	NSLog(@"start ParseBody");
	NSLog(targetText);
#endif
	NSCharacterSet* chSet = [NSCharacterSet characterSetWithCharactersInString:@"()`"];
	//NSCharacterSet* chSet = [NSCharacterSet characterSetWithCharactersInString:@"()"];
	NSString *scannedText;
	NSRange subRange;
	NSScanner *scanner;
	int matchLength;
	
	while(targetText != nil) {
		
		if (wholeLineFlag) {
			targetText = [self parseLines:targetText withList:currentList];
			if (targetText == nil) break;
		}
		targetText = [targetText stringByTrimmingCharactersInSet:whitespaceCharSet];
		scanner = [NSScanner scannerWithString:targetText];
		BOOL scanResult = [scanner scanUpToCharactersFromSet:chSet intoString:&scannedText];
		
		if ([scanner isAtEnd]) {
			[self appendLogRecordWithString:scannedText intoList:currentList];
			targetText = [self getNextLine];
			*wholeLineFlag = YES;
			
		}else {
			if (scanResult) {
				matchLength = [scannedText length];
			}else{
				matchLength = 0;
			}
			subRange = NSMakeRange(matchLength,1);
			if ([targetText compare:@"(" options:nil range:subRange] == NSOrderedSame) {
				if (scanResult) {
					[self appendLogRecordWithString:scannedText intoList:currentList];
				}
				NSMutableArray *newList = [NSMutableArray array];
				[currentList addObject:newList];

				subRange = NSMakeRange(matchLength+1,[targetText length] - matchLength-1);
				if (subRange.length == 0) {
					targetText = [self getNextLine];
					*wholeLineFlag = YES;
				}else{
					targetText = [targetText substringWithRange:subRange];
					*wholeLineFlag = NO;
				}
				targetText = [self parseBodyWith:newList startText:targetText isWholeLine:wholeLineFlag];
			}else if ([targetText compare:@")" options:nil range:subRange] == NSOrderedSame) {
				if (scanResult) {
					[self appendLogRecordWithString:scannedText intoList:currentList];
				}
				subRange = NSMakeRange(matchLength+1,[targetText length] - matchLength-1);
				if (subRange.length == 0) {
					targetText = [self getNextLine];
					*wholeLineFlag = YES;
				}else{
					targetText = [targetText substringWithRange:subRange];
					*wholeLineFlag = NO;
				}
				return targetText;
			}else if ([targetText compare:@"`" options:nil range:subRange] == NSOrderedSame) {
				//this block for ignoring "(" and ")" in between "`" and "'"
				scanResult = [scanner scanUpToString:@"'" intoString:&scannedText];
				matchLength += ([scannedText length]+1);
				if (![scanner isAtEnd]) {
					scanResult = [scanner scanUpToCharactersFromSet:chSet intoString:&scannedText];
					if (scanResult) {
						matchLength += ([scannedText length]-1);
					}
				}
				
				if ([scanner isAtEnd]) {
					[self appendLogRecordWithString:scannedText intoList:currentList];
					targetText = [self getNextLine];
					*wholeLineFlag = YES;
				}else {
					subRange = NSMakeRange(matchLength, [targetText length]-matchLength);
					targetText = [targetText substringWithRange:subRange];
					*wholeLineFlag = NO;
				}
			}
		}
	}
	return targetText;
}

- (NSString *) skipHeader {
	NSString * theLine = [self getNextLine];
	NSRange beginningOne = NSMakeRange(0,1);
	NSString * fistParenth = @"(";
	while (theLine != NULL) {
		if([theLine compare:fistParenth options:nil range:beginningOne] == NSOrderedSame) {
			break;
		}
		theLine = [self getNextLine];
	}
	NSRange subRange = NSMakeRange(1,[theLine length]-1);
	return [theLine substringWithRange:subRange];
}

#pragma mark accessor methods
- (void)setLogContents:(NSString *)logText
{
	[logText retain];
	[logContents release];
	logContents = logText;
}

- (void)setLogFilePath:(NSString *)path
{
	[path retain];
	[logFilePath release];
	logFilePath = path;
}

@end
