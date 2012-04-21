/*
 * SpinTask
 * Why do people want to make tweaks paid?
 *
 * by theiostream listenin' some White Stripes
 */

#import "SpinTask.h"
#include <objc/runtime.h>
#import <libactivator.h>
#import <libdisplaystack/DSDisplayController.h>
#import <QuartzCore/QuartzCore.h>

#define STPreferences "/var/mobile/Library/Preferences/am.theiostre.spintask.plist"

static int l = 4;

static NSDictionary *spinTaskPrefs;
static void STUpdatePrefs() {
	NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:@STPreferences];
	if (!plist) return;
	
	spinTaskPrefs = [plist retain];
}

static id inst = nil;
@interface STActivator : NSObject <LAListener> {
	int pos;
	BOOL tap;
	BOOL show;
	
	NSArray *images;
	NSArray *identifiers;
	
	UIWindow *w;
	UIView *picker;
	dispatch_source_t tmr;
}

- (void)startTimer;
- (void)stopTimer;
- (void)swipe:(UISwipeGestureRecognizer *)rec;
- (void)launch;
- (void)cleanUp;
- (BOOL)showing;
@end

static id STAK(NSDictionary *dict, int c) {
	id k = [dict objectForKey:[NSString stringWithFormat:@"App%i", c]];
	return k ? k : nil;
}

static void STReverse(int *di) {
	NSNumber *re = [spinTaskPrefs objectForKey:@"STInverse"];
	BOOL r = re ? [re boolValue] : YES;
	
	if (r)
		*di = -(*di);
}

static UIImageView *STImageViewForIdentifier(NSString *ide, int i) {
	id icon = [[objc_getClass("SBIconModel") sharedInstance] leafIconForIdentifier:ide];
	UIImage *iconImage = [icon generateIconImage:0];
	
	UIImageView *iconImageView = [[[UIImageView alloc] initWithImage:iconImage] autorelease];
	[iconImageView setFrame:CGRectMake(66*(l==5?i-1:i)+20, 20, 56, 56)];
	
	return iconImageView;
}

static NSArray *STRecentAppsIdentifiers() {
	return [[objc_getClass("SBAppSwitcherModel") sharedInstance] identifiers];
}

static NSDictionary* STRecentAppViews() {
	NSArray *ids;
	NSMutableArray *ret = [NSMutableArray array];
	
	ids = STRecentAppsIdentifiers();
	for (int i=0; i<l; i++) {
		NSString *identifier = [ids objectAtIndex:i];
		
		id topAppId = [[[DSDisplayController sharedInstance] activeApp] displayIdentifier];
		if (i==0 && [topAppId isEqualToString:identifier]) {
			l = 5;
			continue;
		}
		
		UIImageView *imgView = STImageViewForIdentifier(identifier, i);
		[ret addObject:imgView];
	}
	
	NSDictionary *rret = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:ret, ids, nil] forKeys:[NSArray arrayWithObjects:@"Images", @"Identifiers", nil]];
	return rret;
}

static NSDictionary* STChosenAppViews() {
	NSArray *ids;
	NSMutableArray *ret = [NSMutableArray arrayWithCapacity:4];
	
	NSString *app1 = STAK(spinTaskPrefs, 1);
	NSString *app2 = STAK(spinTaskPrefs, 2);
	NSString *app3 = STAK(spinTaskPrefs, 3);
	NSString *app4 = STAK(spinTaskPrefs, 4);
	
	if ((app1 && app2 && app3 && app4)) {
		ids = [NSArray arrayWithObjects:app1, app2, app3, app4, nil];
		for (unsigned int i=0; i<[ids count]; i++) {
			UIImageView *imgView = STImageViewForIdentifier([ids objectAtIndex:i], i);
			[ret addObject:imgView];
		}
		
		NSDictionary *rret = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:ret, ids, nil] forKeys:[NSArray arrayWithObjects:@"Images", @"Identifiers", nil]];
		return rret;
	}
	
	return STRecentAppViews();
}

@implementation STActivator
+ (STActivator *)sharedInstance {
	if (!inst)
		inst = [self new];
	
	return inst;
}

+ (void)load {
	[[LAActivator sharedInstance] registerListener:[STActivator sharedInstance] forName:@"am.theiostre.spintask"];
}

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {	
	if (!w) {
		w = [[UIWindow alloc] initWithFrame:CGRectMake(10, 200, 300, 100)];
		w.windowLevel = 9438;
		w.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
		w.layer.cornerRadius = 5;
		
		picker = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
		picker.alpha = 0.6;
		picker.backgroundColor = [UIColor blackColor];
		picker.layer.cornerRadius = 5;
		[w addSubview:picker];
		
		NSNumber *pann = [spinTaskPrefs objectForKey:@"STPan"];
		BOOL pan = pann ? [pann boolValue] : YES;
		
		NSNumber *touches = [spinTaskPrefs objectForKey:@"STSwipeFingers"];
		NSUInteger tn = touches ? [touches unsignedIntegerValue] : 1;
		
		NSNumber *tapp = [spinTaskPrefs objectForKey:@"STTap"];
		tap = tapp ? [tapp boolValue] : YES;
		
		NSNumber *ttaps = [spinTaskPrefs objectForKey:@"STTapTaps"];
		NSUInteger tpn = ttaps ? [ttaps unsignedIntegerValue] : 1;
		
		NSNumber *ttouches = [spinTaskPrefs objectForKey:@"STTapFingers"];
		NSUInteger ttn = ttouches ? [ttouches unsignedIntegerValue] : 1;
		
		if (pan) {
			UIPanGestureRecognizer *pang = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
			[pang setMaximumNumberOfTouches:tn];
			[pang setMinimumNumberOfTouches:tn];
			
			[w addGestureRecognizer:pang];
			[pang release];
		}
		
		else {
			UISwipeGestureRecognizer *swi = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipe:)];
			swi.numberOfTouchesRequired = tn;
			swi.direction = UISwipeGestureRecognizerDirectionLeft;
			[w addGestureRecognizer:swi];
			[swi release];
			
			UISwipeGestureRecognizer *rswi = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipe:)];
			rswi.numberOfTouchesRequired = tn;
			rswi.direction = UISwipeGestureRecognizerDirectionRight;
			[w addGestureRecognizer:rswi];
			[rswi release];
		}
		
		if (tap) {
			UITapGestureRecognizer *tapg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
			[tapg setNumberOfTouchesRequired:ttn];
			[tapg setNumberOfTapsRequired:tpn];
			
			[w addGestureRecognizer:tapg];
			[tapg release];
		}
	}
	
	if (w.hidden) {
		NSNumber *b = [spinTaskPrefs objectForKey:@"STSelectApps"];
		BOOL s = b ? [b boolValue] : NO;
		
		NSDictionary *rr = s ? STChosenAppViews() : STRecentAppViews();
		images = [[rr objectForKey:@"Images"] retain];
		identifiers = [[rr objectForKey:@"Identifiers"] retain];
		
		for (UIView *v in images) [w addSubview:v];
		
		[w setHidden:NO];
		[picker setFrame:CGRectMake(15, 15, 66, 66)];
		
		pos = 0;
		[self startTimer];
		
		show = YES;
	}
	
	else {
		[self cleanUp];
	}
	
	[event setHandled:YES];
}

- (void)swipe:(UISwipeGestureRecognizer *)rec {
	int di = rec.direction == UISwipeGestureRecognizerDirectionLeft ? -1 : 1;
	STReverse(&di);
	
	if (pos+di<0 || pos+di>3) return;
	else {
		pos += di;
		[picker setFrame:(CGRect){{picker.frame.origin.x+(66*di), picker.frame.origin.y}, picker.frame.size}];
		
		[self stopTimer];
		[self startTimer];
	}
}

- (void)pan:(UIPanGestureRecognizer *)rec {
	static float ploc = 0;
	float loc = [rec locationInView:w].x;
	
	if ([rec state] == UIGestureRecognizerStateBegan)
		ploc = loc;
	
	else if ([rec state] == UIGestureRecognizerStateChanged) {
		int r = -(ploc-loc);
		int di = r>45 ? 1 : r<-45 ? -1 : 0;
		if (di == 0) return;
		STReverse(&di);
		
		if (pos+di<0 || pos+di>3) return;
		else {
			pos += di;
			
			NSLog(@"[SpinTask] DEBUG: Numbers! %i %i", r, di);
			
			[picker setFrame:(CGRect){{picker.frame.origin.x+(66*di), picker.frame.origin.y}, picker.frame.size}];
			[self stopTimer];
			[self startTimer];
			
			ploc = loc;
		}
	}
}

- (void)tap:(UITapGestureRecognizer *)rec {
	if ([rec state] == UIGestureRecognizerStateEnded)
		[self launch];
}
	
// TODO: Allow user to choose time for launch?
- (void)startTimer {
	if (tap) return;
	
	tmr = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
	dispatch_source_set_timer(tmr, dispatch_time(DISPATCH_TIME_NOW, 1.3*NSEC_PER_SEC), DISPATCH_TIME_FOREVER, 0);
	dispatch_source_set_event_handler(tmr, ^{
		[self launch];
	});
	
	dispatch_resume(tmr);
}

- (void)stopTimer {
	if (tmr) {
		dispatch_source_cancel(tmr);
		dispatch_release(tmr);
		tmr = NULL;
	}
}

- (void)launch {
	[[DSDisplayController sharedInstance] activateAppWithDisplayIdentifier:[identifiers objectAtIndex:(l==5?pos+1:pos)] animated:YES];
	[self cleanUp];
}

- (void)cleanUp {
	[self stopTimer];
	
	l = 4;
	
	[images release];
	[identifiers release];
	[w release];
	w = nil;
	
	show = NO;
}

- (BOOL)showing {
	return show;
}

- (void)dealloc {
	[super dealloc];
	
	if ((w)) {
		if (!(w.hidden)) [self cleanUp];
		[w release];
	}
}
@end

// *****************

typedef struct __GSEvent* GSEventRef;

%hook SpringBoard
- (void)menuButtonDown:(GSEventRef)down {
	id act = [STActivator sharedInstance];
	
	if ([act showing]) [act cleanUp];
	else			   %orig;
}

- (void)lockButtonDown:(GSEventRef)down {
	id act = [STActivator sharedInstance];
	
	if ([act showing]) [act cleanUp];
	else			   %orig;
}
%end

static void STReloadPrefs(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	STUpdatePrefs();
}

__attribute__((constructor))
static void STInit() {
	NSAutoreleasePool *p = [NSAutoreleasePool new];
	
	STUpdatePrefs();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
									NULL,
									&STReloadPrefs,
									CFSTR("am.theiostre.spintask.reload"),
									NULL,
									0);
	
	[p drain];
}