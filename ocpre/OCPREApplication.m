//
//  OCPREApplication.m
//  ocpre
//
//  Created by Uli Kusterer on 26.07.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#import "OCPREApplication.h"


@implementation OCPREApplication

+(NSString*) syntaxForExecutablePath: (NSString*)inPath
{
	return [NSString stringWithFormat: @"%@ [--generate-localized-strings 1] <fileName>\nPreprocess the given file.\n\t--generate-localized-strings\tSpecify this option to have a .strings file generated to hold the format strings.", inPath];
}

-(BOOL) openFile: (NSString*)filePath
{
	NSError * err = nil;
	NSString * fileStr = [NSString stringWithContentsOfFile: filePath encoding: NSUTF8StringEncoding error: &err];
	if (!fileStr) {
		NSLog( @"Error: Couldn't load file: %@ Reason: %@", filePath, err );
		return NO;
	}
	
	BOOL generateLocalizedStrings = [[NSUserDefaults standardUserDefaults] boolForKey: @"-generate-localized-strings"];
	
	NSMutableString * processedFileStr = [NSMutableString string];
	NSMutableString * localizedFileStr = [NSMutableString string];
	NSCharacterSet * stringEndChars = [NSCharacterSet characterSetWithCharactersInString: @"\\\""];
	NSCharacterSet * bracketChars = [NSCharacterSet characterSetWithCharactersInString: @"()"];
	NSScanner * scanner = [NSScanner scannerWithString: fileStr];
	scanner.charactersToBeSkipped = nil;
	while (!scanner.atEnd) {	// Search for string literals:
		int argPosition = 0;
		NSString * partBefore = nil;
		[scanner scanUpToString: @"@\"" intoString: &partBefore];
		if (!partBefore) {
			partBefore = @"";
		}
		[processedFileStr appendString: partBefore];
		if (scanner.atEnd)
			break;
		[scanner scanString: @"@\"" intoString: nil];
		NSMutableString * formatString = [NSMutableString string];
		if (!generateLocalizedStrings) {
			[formatString appendString: @"@\""];
		}
		NSMutableString * formatArgsString = [NSMutableString string];
		BOOL stringEnded = NO;
		while (!scanner.atEnd && !stringEnded) {	// Search for escape sequences/their ends:
			NSString * stringContents = nil;
			[scanner scanUpToCharactersFromSet: stringEndChars intoString: &stringContents];
			if (!stringContents) stringContents = @"";
			[formatString appendString: stringContents];
			
			NSString * endChar = nil;
			[scanner scanCharactersFromSet: stringEndChars intoString: &endChar];
			if (!stringContents) endChar = @"";
			while (endChar.length > 0) {	// Scanner may give us several escape sequences, if they're in a row:
				if (scanner.atEnd) {
					break;
				}
				else if ([endChar hasPrefix: @"\\\\"]) {	// Escaped backslash.
					[formatString appendString: @"\\\\"];
					endChar = [endChar substringFromIndex: 2];
				} else if ([endChar hasPrefix: @"\\\""]) { // Escaped quote.
					[formatString appendString: @"\\\""];
					endChar = [endChar substringFromIndex: 2];
				} else if ([endChar hasPrefix: @"\""]) { // String-ending quote.
					if (!generateLocalizedStrings) {
						[formatString appendString: @"\""];
					}
					stringEnded = YES;
					break;	// TODO: Doesn't correctly handle strings like "foo""bar" without a space between them.
				} else if ([endChar isEqualToString: @"\\"] && !scanner.atEnd) { // Some other escape sequence, possibly "\(".
					endChar = @"";
					unichar escapedCh = [fileStr characterAtIndex: scanner.scanLocation];
					scanner.scanLocation = scanner.scanLocation +1;
					if (escapedCh == '(') {
						int bracketCount = 1;
						[formatString appendFormat: @"%%%d$@", ++argPosition];
						[formatArgsString appendString: @", ("];
						
						BOOL interpolatedSectionDone = NO;
						while (!scanner.isAtEnd && !interpolatedSectionDone) {	// Loop over brackets to balance the ones in code & find our end indicator.
							NSString * exprPart = nil;
							[scanner scanUpToCharactersFromSet: bracketChars intoString: &exprPart];
							[formatArgsString appendString: exprPart];
							
							NSString * bracketString = nil;
							[scanner scanCharactersFromSet: bracketChars intoString: &bracketString];
							if (!bracketString) bracketString = @"";
							
							// Again, may get several brackets from scanner, but may also get brackets as part of text *after* our interpolation:
							for (NSInteger x = 0; x < bracketString.length && !interpolatedSectionDone; x++) {
								switch ([bracketString characterAtIndex: x]) {
									case '(':
										++bracketCount;
										[formatArgsString appendString: @"("];
										break;
									case ')':
										--bracketCount;
										if (bracketCount == 0) {
											[formatString appendString: [bracketString substringFromIndex: x +1]];
											interpolatedSectionDone = YES;
										} else {
											[formatArgsString appendString: @")"];
										}
										break;
								}
							}
						}
						[formatArgsString appendString: @")"];
					} else {
						[formatString appendFormat: @"\\%C", escapedCh];
					}
				} else {
					NSLog( @"Error: Couldn't parse string near '%C' (%ld).", [fileStr characterAtIndex: scanner.scanLocation], (long)scanner.scanLocation );
					return NO;
				}
			}
		}
		if (generateLocalizedStrings && formatArgsString.length > 0) {
			NSString * fnameKey = [[filePath lastPathComponent] stringByDeletingPathExtension];
			NSString * locKey = [NSString stringWithFormat: @"%@_%lx", [fnameKey uppercaseString], (long)formatString.hash];
			[processedFileStr appendFormat: @"NSLocalizedStringFromTable(@\"%1$@\",@\"%2$@\",@\"%3$@\")%4$@", locKey, fnameKey, formatString, formatArgsString];
			[localizedFileStr appendFormat: @"\"%@\" = \"%@\";\n", locKey, formatString];
		} else {
			[processedFileStr appendFormat: @"%@%@", formatString, formatArgsString];
		}
	}
	
	NSString * processedPath = [[filePath stringByDeletingPathExtension] stringByAppendingFormat: @".processed.%@", filePath.pathExtension];
	if (![processedFileStr writeToFile: processedPath atomically: YES encoding: NSUTF8StringEncoding error: &err]) {
		NSLog(@"Error writing processed file: %@", err);
	}
	if (generateLocalizedStrings && localizedFileStr.length > 0) {
		NSString * localizedPath = [[filePath stringByDeletingPathExtension] stringByAppendingPathExtension: @"strings"];
		if (![localizedFileStr writeToFile: localizedPath atomically: YES encoding: NSUTF8StringEncoding error: &err]) {
			NSLog(@"Error writing strings file: %@", err);
		}
	}
	
	return YES;
}

@end
