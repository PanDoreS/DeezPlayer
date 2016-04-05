//
//  MainWindowController.m
//  DeezPlayer
//
//  Created by Bernard Potocki on 19.06.2012.
//  Copyright (c) 2012 Imanel. All rights reserved.
//

#import "MainWindowController.h"
#import "AppDelegate.h"

@implementation MainWindowController

NSString *old_current_song;
NSTimer *t;

- (void)awakeFromNib {
    [self setBackground];
    [self setUserAgent];
    [self setUserStylesheet];
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    [[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://deezer.com/"]]];
    t = [NSTimer scheduledTimerWithTimeInterval:0.5
                                         target:self
                                       selector:@selector(updateString)
                                       userInfo:nil
                                        repeats:YES];
}

- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame {
    if (frame == [sender mainFrame])
        [[self window] setTitle:title];
    
}

-(void)updateString
{
    NSString *current_song = [webView stringByEvaluatingJavaScriptFromString:@"dzPlayer.getCurrentSong()['SNG_ID'];"];
    if(current_song != old_current_song){
        NSString *img_cover_url =  [NSString stringWithFormat:@"%@%@%@",
                                    @"http://api.deezer.com/2.0/album/",
                                    [webView stringByEvaluatingJavaScriptFromString:@"dzPlayer.getCurrentSong()['ALB_ID'];"],
                                    @"/image?size=medium"];
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = [webView stringByEvaluatingJavaScriptFromString:@"dzPlayer.getCurrentSong()['SNG_TITLE'];"];
        notification.informativeText = [webView stringByEvaluatingJavaScriptFromString:@"dzPlayer.getCurrentSong()['ART_NAME'];"];
        NSImage * img_data = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:img_cover_url]];
        notification.contentImage = img_data;
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        
        //t.invalidate;
    }
    old_current_song = current_song;

}


- (void) setUserAgent {
    NSString *safariVersion = @"5.1.7";
    NSString *userAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];

    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"WebKit\\/([\\d.]+)" options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *matches = [regex matchesInString:userAgent options:0 range:NSMakeRange(0, [userAgent length])];
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match rangeAtIndex:1];
        NSString *webKitVersion = [userAgent substringWithRange:matchRange];

        userAgent = [NSString stringWithFormat:@"%@ Version/%@ Safari/%@", userAgent, safariVersion, webKitVersion];
        [webView setCustomUserAgent:userAgent];
    }
    
}

- (void)webView:(WebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WebFrame *)frame {
	NSRunInformationalAlertPanel(NSLocalizedString(@"JavaScript", @""),	// title
								 message,								// message
								 NSLocalizedString(@"OK", @""),			// default button
								 nil,									// alt button
								 nil);									// other button
}


- (BOOL)webView:(WebView *)sender runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WebFrame *)frame {
	NSInteger result = NSRunInformationalAlertPanel(NSLocalizedString(@"JavaScript", @""),	// title
													message,								// message
													NSLocalizedString(@"OK", @""),			// default button
													NSLocalizedString(@"Cancel", @""),		// alt button
													nil);
	return NSAlertDefaultReturn == result;
}

- (void)webView:(WebView *)sender runOpenPanelForFileButtonWithResultListener:(id < WebOpenPanelResultListener >)resultListener {
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];

    [openDlg setCanChooseFiles:YES];
    [openDlg setCanChooseDirectories:NO];
    [openDlg setAllowsMultipleSelection:YES];

    if ( [openDlg runModal] == NSOKButton )
    {
        NSArray* files = [[openDlg URLs]valueForKey:@"relativePath"];
        [resultListener chooseFilenames:files];
    }
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    if(frame == [sender mainFrame]) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"custom" ofType:@"js"];
        NSString *js = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        [webView stringByEvaluatingJavaScriptFromString:js];
        [webView stringByEvaluatingJavaScriptFromString:@"document.body.style.zoom='80%'"];
    }
}

- (void)togglePlayPause {
    [webView stringByEvaluatingJavaScriptFromString:@"dzPlayer.control.togglePause();"];
}

- (void)playNext {
    [webView stringByEvaluatingJavaScriptFromString:@"dzPlayer.control.nextSong();"];
}

- (void)playPrev {
    [webView stringByEvaluatingJavaScriptFromString:@"dzPlayer.control.prevSong();"];
}

- (void)setBackground {
    [webView setDrawsBackground:NO];
    [[self window] setBackgroundColor:NSColor.blackColor];

    NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 480, 215)];
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"deezer-logo" ofType:@"png"];
    NSImage *image = [[NSImage alloc]initWithContentsOfFile:imagePath];
    [imageView setImage:image];
    [view addSubview:imageView positioned:NSWindowBelow relativeTo:webView];
    [imageView setFrameOrigin:NSMakePoint(
                                        (NSWidth([view bounds]) - NSWidth([imageView frame])) / 2,
                                        (NSHeight([view bounds]) - NSHeight([imageView frame])) / 2
                                        )];
    [imageView setAutoresizingMask:NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin];
}

- (void)setUserStylesheet {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"custom" ofType:@"css"];
    NSURL *fileURL = [NSURL URLWithString:filePath];

    [[webView preferences] setUserStyleSheetEnabled:YES];
    [[webView preferences] setUserStyleSheetLocation:fileURL];
}


@end
