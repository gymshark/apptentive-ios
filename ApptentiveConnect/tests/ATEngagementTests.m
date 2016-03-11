//
//  ATEngagementTests.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 9/5/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ATConnect.h"
#import "ATInteraction.h"
#import "ATInteractionInvocation.h"
#import "ATInteractionUsageData.h"
#import "ATEngagementBackend.h"
#import "ATConnect_Private.h"


@interface ATEngagementTests : XCTestCase
@end


@implementation ATEngagementTests

/*
 time_since_install/total - The total time in seconds since the app was installed (double)
 time_since_install/version - The total time in seconds since the current app version name was installed (double)
 time_since_install/build - The total time in seconds since the current app build number was installed (double)

 application_version - The currently running application version (string).
 application_build - The currently running application build "number" (string).
 current_time - The current time as a numeric Unix timestamp in seconds.

 app_release/version - The currently running application version (string).
 app_release/build - The currently running application build "number" (string).

 sdk/version - The currently running SDK version (string).
 sdk/distribution - The current SDK distribution, if available (string).
 sdk/distribution_version - The current version of the SDK distribution, if available (string).

 is_update/version - Returns true if we have seen a version prior to the current one.
 is_update/build - Returns true if we have seen a build prior to the current one.

 code_point.code_point_name.invokes.total - The total number of times code_point_name has been invoked across all versions of the app (regardless if an Interaction was shown at that point)  (integer)
 code_point.code_point_name.invokes.version - The number of times code_point_name has been invoked in the current version of the app (regardless if an Interaction was shown at that point) (integer)
 interactions.interaction_instance_id.invokes.total - The number of times the Interaction Instance with id interaction_instance_id has been invoked (irrespective of app version) (integer)
 interactions.interaction_instance_id.invokes.version  - The number of times the Interaction Instance with id interaction_instance_id has been invoked within the current version of the app (integer)
*/

- (void)testEventLabelsContainingCodePointSeparatorCharacters {
	//Escape "%", "/", and "#".

	NSString *i, *o;
	i = @"testEventLabelSeparators";
	o = @"testEventLabelSeparators";
	XCTAssertTrue([[ATEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test#Event#Label#Separators";
	o = @"test%23Event%23Label%23Separators";
	XCTAssertTrue([[ATEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test/Event/Label/Separators";
	o = @"test%2FEvent%2FLabel%2FSeparators";
	XCTAssertTrue([[ATEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test%Event/Label#Separators";
	o = @"test%25Event%2FLabel%23Separators";
	XCTAssertTrue([[ATEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test#Event/Label%Separators";
	o = @"test%23Event%2FLabel%25Separators";
	XCTAssertTrue([[ATEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test###Event///Label%%%Separators";
	o = @"test%23%23%23Event%2F%2F%2FLabel%25%25%25Separators";
	XCTAssertTrue([[ATEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test#%///#%//%%/#Event_!@#$%^&*(){}Label1234567890[]`~Separators";
	o = @"test%23%25%2F%2F%2F%23%25%2F%2F%25%25%2F%23Event_!@%23$%25^&*(){}Label1234567890[]`~Separators";
	XCTAssertTrue([[ATEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test%/#";
	o = @"test%25%2F%23";
	XCTAssertTrue([[ATEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");
}

- (void)testInteractionCriteria {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	invocation.criteria = @{ @"time_since_install/total": @{@"$gt": @(5 * 60 * 60 * 24), @"$lt": @(7 * 60 * 60 * 24)} };

	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] initWithEngagementData:@{ ATEngagementInstallDateKey: [NSDate dateWithTimeIntervalSinceNow:-6 * 60 * 60 *24] }];

	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Install date");
}

- (void)testUnknownKeyInCriteria {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	invocation.criteria = @{ @"time_since_install/total": @{@"$gt": @(5 * 60 * 60 * 24), @"$lt": @(7 * 60 * 60 * 24)} };

	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] initWithEngagementData:@{ ATEngagementInstallDateKey: [NSDate dateWithTimeIntervalSinceNow:-6 * 60 * 60 *24] }];

	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"All keys are known, thus the criteria is met.");

	invocation.criteria = @{ @"time_since_install/total": @6,
		@"unknown_key": @"criteria_should_not_be_met" };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Criteria should not be met if the criteria includes a key that the client does not recognize.");

	invocation.criteria = @{ @6: @"this is weird" };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Criteria should not be met if the criteria includes a key that the client does not recognize.");
}

- (void)testEmptyCriteria {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];

	invocation.criteria = nil;
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Dictionary with nil criteria should evaluate to False.");

	invocation.criteria = @{[NSNull null]: [NSNull null]};
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Dictionary with Null criteria should evaluate to False.");

	invocation.criteria = @{};
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Empty criteria dictionary with no keys should evaluate to True.");

	invocation.criteria = @{ @"": @6 };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Criteria with a key that is an empty string should fail (if usage data does not match).");
}

- (void)testInteractionCriteriaDaysSnceInstall {
	NSMutableDictionary *engagementData = [NSMutableDictionary dictionary];
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] initWithEngagementData:engagementData];

	NSTimeInterval dayTimeInterval = 60 * 60 * 24;

	invocation.criteria = @{ @"time_since_install/total": @{@"$gt": @(5 * dayTimeInterval), @"$lt": @(7 * dayTimeInterval)} };
	engagementData[ATEngagementInstallDateKey] = [NSDate dateWithTimeIntervalSinceNow:-6 * dayTimeInterval];
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Install date");
	engagementData[ATEngagementInstallDateKey] = [NSDate dateWithTimeIntervalSinceNow:-4.999 * dayTimeInterval];
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Install date");
	engagementData[ATEngagementInstallDateKey] = [NSDate dateWithTimeIntervalSinceNow:-7.001 * dayTimeInterval];
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Install date");

	invocation.criteria = @{ @"time_since_install/total": @{@"$lte": @(5 * dayTimeInterval), @"$gt": @(3 * dayTimeInterval)} };
	engagementData[ATEngagementInstallDateKey] = [NSDate dateWithTimeIntervalSinceNow:-2.999 * dayTimeInterval];
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Install date");
	engagementData[ATEngagementInstallDateKey] = [NSDate dateWithTimeIntervalSinceNow:-4 * dayTimeInterval];
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Install date");
	engagementData[ATEngagementInstallDateKey] = [NSDate dateWithTimeIntervalSinceNow:-4.999 * dayTimeInterval ];
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Install date");
	engagementData[ATEngagementInstallDateKey] = [NSDate dateWithTimeIntervalSinceNow:-6 * dayTimeInterval];
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Install date");


	invocation.criteria = @{ @"time_since_install/total": @{@"$lte": @"5", @"$gt": @"3"} };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Should fail with invalid types.");
}

- (void)testInteractionCriteriaVersion {
	NSMutableDictionary *engagementData = [NSMutableDictionary dictionary];

	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] initWithEngagementData:engagementData];

	invocation.criteria = @{ @"application_version": @"1.2.8" };
	engagementData[ATEngagementApplicationVersionKey] = @"1.2.8";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Version number");
	engagementData[ATEngagementApplicationVersionKey] = @"v1.2.8";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Version number must not have a 'v' in front!");

	invocation.criteria = @{ @"application_version": @"v3.0" };
	engagementData[ATEngagementApplicationVersionKey] = @"v3.0";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Version number");
	engagementData[ATEngagementApplicationVersionKey] = @"3.0";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Version number must not have a 'v' in front!");

	invocation.criteria = @{ @"app_release/version": @"1.2.8" };
	engagementData[ATEngagementApplicationVersionKey] = @"1.2.8";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Version number");
	engagementData[ATEngagementApplicationVersionKey] = @"v1.2.8";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Version number must not have a 'v' in front!");

	invocation.criteria = @{ @"app_release/version": @"v3.0" };
	engagementData[ATEngagementApplicationVersionKey] = @"v3.0";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Version number");
	engagementData[ATEngagementApplicationVersionKey] = @"3.0";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Version number must not have a 'v' in front!");

	invocation.criteria = @{ @"app_release/version": @{@"$gt": @3.0} };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Should fail with invalid types.");
}

- (void)testInteractionCriteriaBuild {
	NSMutableDictionary *engagementData = [NSMutableDictionary dictionary];

	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] initWithEngagementData:engagementData];

	invocation.criteria = @{ @"application_build": @"39" };
	engagementData[ATEngagementApplicationBuildKey] = @"39";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Build number");

	engagementData[ATEngagementApplicationBuildKey] = @"v39";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Build number must not have a 'v' in front!");

	invocation.criteria = @{ @"application_build": @"v3.0" };
	engagementData[ATEngagementApplicationBuildKey] = @"v3.0";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Build number");

	engagementData[ATEngagementApplicationBuildKey] = @"3.0";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Build number must not have a 'v' in front!");

	invocation.criteria = @{ @"app_release/build": @"39" };
	engagementData[ATEngagementApplicationBuildKey] = @"39";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Build number");

	engagementData[ATEngagementApplicationBuildKey] = @"v39";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Build number must not have a 'v' in front!");

	invocation.criteria = @{ @"app_release/build": @"v3.0" };
	engagementData[ATEngagementApplicationBuildKey] = @"v3.0";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Build number");

	engagementData[ATEngagementApplicationBuildKey] = @"3.0";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Build number must not have a 'v' in front!");

	invocation.criteria = @{ @"app_release/build": @{@"$contains": @3.0} };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Should fail with invalid types.");
}

- (void)testInteractionCriteriaSDK {
	NSMutableDictionary *engagementData = [NSMutableDictionary dictionary];

	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] initWithEngagementData:engagementData];

	invocation.criteria = @{ @"sdk/version": [ATConnect versionObjectWithVersion:kATConnectVersionString] };
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Default value should be current version.");

	invocation.criteria = @{ @"sdk/version": [ATConnect versionObjectWithVersion:@"1.4.2"] };
	engagementData[ATEngagementSDKVersionKey] = @"1.4.2";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"SDK Version should be 1.4.2");

	engagementData[ATEngagementSDKVersionKey] = @"1.4";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"SDK Version isn't 1.4");

	engagementData[ATEngagementSDKVersionKey] = @"1.5.0";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"SDK Version isn't 1.5.0");

	invocation.criteria = @{ @"sdk/version": @{@"$contains": @3.0} };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Should fail with invalid types.");

	invocation.criteria = @{ @"sdk/distribution": @"CocoaPods-Source" };
	engagementData[ATEngagementSDKDistributionNameKey] = @"CocoaPods-Source";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"SDK Distribution should be CocoaPods-Source");

	invocation.criteria = @{ @"sdk/distribution": @{@"$contains": @"CocoaPods"} };
	engagementData[ATEngagementSDKDistributionNameKey] = @"CocoaPods-Source";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"SDK Distribution should contain CocoaPods");

	invocation.criteria = @{ @"sdk/distribution_version": @"foo" };
	engagementData[ATEngagementSDKDistributionVersionKey] = @"foo";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"SDK Distribution Version should match.");
}

- (void)testInteractionCriteriaCurrentTime {
	NSMutableDictionary *engagementData = [NSMutableDictionary dictionary];

	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] initWithEngagementData:engagementData];

	invocation.criteria = @{ @"current_time": @{@"$exists": @YES} };
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Must have default current time.");
	// Make sure it's actually a reasonable value…
	NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
	NSTimeInterval timestamp = [usageData.currentTime doubleValue];
	XCTAssertEqualWithAccuracy(timestamp, currentTimestamp, 0.01, @"Current time not a believable value.");

	invocation.criteria = @{ @"current_time": @{@"$gt": [ATConnect timestampObjectWithDate:[NSDate dateWithTimeIntervalSince1970:1397598108.63843]]} };
	usageData.currentTimeOffset = [[NSDate dateWithTimeIntervalSince1970:1397598109] timeIntervalSinceNow];
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Current time criteria not met.");

	invocation.criteria = @{ @"current_time": @{@"$lt": [ATConnect timestampObjectWithDate:[NSDate dateWithTimeIntervalSince1970:1183135260]], @"$gt": [ATConnect timestampObjectWithDate:[NSDate dateWithTimeIntervalSince1970:465498000]]} };
	usageData.currentTimeOffset = [[NSDate dateWithTimeIntervalSince1970:1183135259.5] timeIntervalSinceNow];
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Current time criteria not met.");

	invocation.criteria = @{ @"current_time": @{@"$gt": @"1183135260"} };
	usageData.currentTimeOffset = [[NSDate dateWithTimeIntervalSince1970:1397598109] timeIntervalSinceNow];
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Should fail because of type but not crash.");

	invocation.criteria = @{ @"current_time": @"1397598109" };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Should fail with invalid types.");
}

- (void)testUpgradeMessageCriteria {
	NSMutableDictionary *engagementData = [NSMutableDictionary dictionary];

	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] initWithEngagementData:engagementData];

	invocation.criteria = @{ @"code_point/app.launch/invokes/version": @1,
		@"application_version": @"1.3.0",
		@"application_build": @"39" };

	engagementData[ATEngagementApplicationVersionKey] = @"1.3.0";

	engagementData[ATEngagementCodePointsInvokesVersionKey] = @{ @"app.launch": @1 };
	engagementData[ATEngagementApplicationVersionKey] = @"1.3.0";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Test Upgrade Message without build number.");
	engagementData[ATEngagementApplicationBuildKey] = @"39";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	engagementData[ATEngagementCodePointsInvokesVersionKey] = @{ @"app.launch": @2 };
	engagementData[ATEngagementApplicationVersionKey] = @"1.3.0";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	engagementData[ATEngagementCodePointsInvokesVersionKey] = @{ @"app.launch": @1 };
	engagementData[ATEngagementApplicationVersionKey] = @"1.3.1";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");

	invocation.criteria = @{ @"application_version": @"1.3.0",
		@"code_point/app.launch/invokes/version": @{@"$gte": @1} };
	engagementData[ATEngagementCodePointsInvokesVersionKey] = @{ @"app.launch": @1 };
	engagementData[ATEngagementApplicationVersionKey] = @"1.3.0";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	engagementData[ATEngagementCodePointsInvokesVersionKey] = @{ @"app.launch": @2 };
	engagementData[ATEngagementApplicationVersionKey] = @"1.3.0";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	engagementData[ATEngagementCodePointsInvokesVersionKey] = @{ @"app.launch": @0 };
	engagementData[ATEngagementApplicationVersionKey] = @"1.3.0";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");

	invocation.criteria = @{ @"application_version": @"1.3.0",
		@"code_point/app.launch/invokes/version": @{@"$lte": @4} };
	engagementData[ATEngagementCodePointsInvokesVersionKey] = @{ @"app.launch": @1 };
	engagementData[ATEngagementApplicationVersionKey] = @"1.3.0";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	engagementData[ATEngagementCodePointsInvokesVersionKey] = @{ @"app.launch": @4 };
	engagementData[ATEngagementApplicationVersionKey] = @"1.3.0";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	engagementData[ATEngagementCodePointsInvokesVersionKey] = @{ @"app.launch": @5 };
	engagementData[ATEngagementApplicationVersionKey] = @"1.3.0";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");

	invocation.criteria = @{ @"code_point/app.launch/invokes/version": @[@1],
		@"application_version": @"1.3.0",
		@"application_build": @"39" };
	engagementData[ATEngagementCodePointsInvokesVersionKey] = @{ @"app.launch": @1 };
	engagementData[ATEngagementApplicationVersionKey] = @"1.3.0";
	engagementData[ATEngagementApplicationBuildKey] = @"39";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Should fail with invalid types.");
}

- (void)testNewUpgradeMessageCriteria {
	NSString *jsonString = @"{\"interactions\":[{\"id\":\"52fadf097724c5c09f000012\",\"type\":\"UpgradeMessage\",\"configuration\":{}}],\"targets\":{\"local#app#upgrade_message_test\":[{\"interaction_id\":\"52fadf097724c5c09f000012\",\"criteria\":{\"application_version\":\"999\",\"time_since_install/version\":{\"$lt\":604800},\"is_update/version\":true,\"interactions/52fadf097724c5c09f000012/invokes/total\":0}}]}}";

	/*
	targets = {
		"local#app#upgrade_message_test" = (
											{
												criteria = {
													"application_version" = 999;
													"interactions/52fadf097724c5c09f000012/invokes/total" = 0;
													"is_update/version" = 1;
													"time_since_install/version" = {
														"$lt" = 604800;
													};
												};
												"interaction_id" = 52fadf097724c5c09f000012;
											}
											);
	};
	*/

	NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:nil];

	NSDictionary *targetsDictionary = jsonDictionary[@"targets"];

	NSString *targetedEvent = [[ATInteraction localAppInteraction] codePointForEvent:@"upgrade_message_test"];
	NSDictionary *appLaunchInteraction = [[targetsDictionary objectForKey:targetedEvent] objectAtIndex:0];

	ATInteractionInvocation *upgradeMessageInteractionInvocation = [ATInteractionInvocation invocationWithJSONDictionary:appLaunchInteraction];

	NSMutableDictionary *engagementData = [NSMutableDictionary dictionary];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] initWithEngagementData:engagementData];

	engagementData[ATEngagementApplicationVersionKey] = @"999";
	engagementData[ATEngagementInteractionsInvokesTotalKey] = @{ @"52fadf097724c5c09f000012": @0 };
	engagementData[ATEngagementIsUpdateVersionKey] = @YES;
	engagementData[ATEngagementInstallDateKey] = [NSDate dateWithTimeIntervalSinceNow:-2 * 24 * 60 * 60];
	XCTAssertTrue([upgradeMessageInteractionInvocation criteriaAreMetForUsageData:usageData], @"Upgrade Message criteria met!");

	engagementData[ATEngagementApplicationVersionKey] = @"998";
	engagementData[ATEngagementInteractionsInvokesTotalKey] = @{ @"52fadf097724c5c09f000012": @0 };
	engagementData[ATEngagementIsUpdateVersionKey] = @YES;
	engagementData[ATEngagementInstallDateKey] = [NSDate dateWithTimeIntervalSinceNow:-2 * 24 * 60 * 60];
	XCTAssertFalse([upgradeMessageInteractionInvocation criteriaAreMetForUsageData:usageData], @"Upgrade Message criteria not met!");

	engagementData[ATEngagementApplicationVersionKey] = @"999";
	engagementData[ATEngagementInteractionsInvokesTotalKey] = @{ @"52fadf097724c5c09f000012": @0 };
	engagementData[ATEngagementIsUpdateVersionKey] = @NO;
	engagementData[ATEngagementInstallDateKey] = [NSDate dateWithTimeIntervalSinceNow:-2 * 24 * 60 * 60];
	XCTAssertFalse([upgradeMessageInteractionInvocation criteriaAreMetForUsageData:usageData], @"Upgrade Message criteria not met!");

	engagementData[ATEngagementApplicationVersionKey] = @"999";
	engagementData[ATEngagementInteractionsInvokesTotalKey] = @{ @"52fadf097724c5c09f000012": @1 };
	engagementData[ATEngagementIsUpdateVersionKey] = @YES;
	engagementData[ATEngagementInstallDateKey] = [NSDate dateWithTimeIntervalSinceNow:-2 * 24 * 60 * 60];
	XCTAssertFalse([upgradeMessageInteractionInvocation criteriaAreMetForUsageData:usageData], @"Upgrade Message criteria not met!");
}

/*
 {
	"$or": [
		{
			"time_since_install/version": {
				"$lt": 259200
			}
		},
		{
			"$and": [
				{
					"code_point/app.launch/invokes/total": 2
				},
				{
					"interactions/526fe2836dd8bf546a00000b/invokes/version": 0
				},
				{
					"$or": [
						{
							"code_point/small.win/invokes/total": @2
						},
						{
							"code_point/big.win/invokes/total": @2
						}
					]
				}
			]
		}
	]
}
 */

- (void)testComplexCriteria {
	NSDictionary *complexCriteria = @{ @"$or": @[@{@"time_since_install/version": @{@"$lt": @(259200)}},
		@{@"$and": @[@{@"code_point/app.launch/invokes/total": @2},
			@{@"interactions/526fe2836dd8bf546a00000b/invokes/version": @0},
			@{@"$or": @[@{@"code_point/small.win/invokes/total": @2},
				@{@"code_point/big.win/invokes/total": @2}]}]}]
	};

	NSMutableDictionary *engagementData = [NSMutableDictionary dictionary];

	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] initWithEngagementData:engagementData];
	engagementData[ATEngagementInteractionsInvokesVersionKey] = @{ @"526fe2836dd8bf546a00000b": @0 };

	invocation.criteria = complexCriteria;

	NSTimeInterval dayTimeInterval = 60 * 60 * 24;

	engagementData[ATEngagementInstallDateKey] = [NSDate dateWithTimeIntervalSinceNow:-2 * dayTimeInterval];
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"2 satisfies the inital OR clause; passes regardless of the next condition.");
	engagementData[ATEngagementInstallDateKey] = [NSDate dateWithTimeIntervalSinceNow:-0 * dayTimeInterval];
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"0 satisfies the inital OR clause; passes regardless of the next condition.");

	engagementData[ATEngagementUpgradeDateKey] = [NSDate dateWithTimeIntervalSinceNow:-3 * dayTimeInterval];
	engagementData[ATEngagementCodePointsInvokesTotalKey] = @{ @"app.launch": @8 };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"3 fails the initial OR clause. 8 fails the other clause.");

	engagementData[ATEngagementInstallDateKey] = [NSDate dateWithTimeIntervalSinceNow:-3 * dayTimeInterval];
	engagementData[ATEngagementInteractionsInvokesVersionKey] = @{ @"526fe2836dd8bf546a00000b": @0 };
	engagementData[ATEngagementCodePointsInvokesTotalKey] = @{ @"app.launch": @2, @"small.win": @0, @"big.win": @2 };
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"complex");
	engagementData[ATEngagementCodePointsInvokesTotalKey] = @{ @"app.launch": @2, @"small.win": @2, @"big.win": @19 };
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"complex");
	engagementData[ATEngagementCodePointsInvokesTotalKey] = @{ @"app.launch": @2, @"small.win": @19, @"big.win": @19 };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Neither of the last two ORed code_point totals are right.");
	engagementData[ATEngagementCodePointsInvokesTotalKey] = @{ @"app.launch": @2, @"small.win": @2, @"big.win": @1 };
	engagementData[ATEngagementInteractionsInvokesVersionKey] = @{ @"526fe2836dd8bf546a00000b": @8 };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"The middle case is incorrect.");
}

- (void)testIsUpdateVersionsAndBuilds {
	NSMutableDictionary *engagementData = [NSMutableDictionary dictionary];

	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] initWithEngagementData:engagementData];

	//Version
	invocation.criteria = @{ @"is_update/version": @YES };
	engagementData[ATEngagementIsUpdateVersionKey] = @YES;
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Test isUpdate");

	invocation.criteria = @{ @"is_update/version": @NO };
	engagementData[ATEngagementIsUpdateVersionKey] = @NO;
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Test isUpdate");

	invocation.criteria = @{ @"is_update/version": @YES };
	engagementData[ATEngagementIsUpdateVersionKey] = @NO;
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Test isUpdate");

	invocation.criteria = @{ @"is_update/version": @NO };
	engagementData[ATEngagementIsUpdateVersionKey] = @YES;
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Test isUpdate");

	//Build
	invocation.criteria = @{ @"is_update/build": @YES };
	engagementData[ATEngagementIsUpdateBuildKey] = @YES;
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Test isUpdate");

	invocation.criteria = @{ @"is_update/build": @NO };
	engagementData[ATEngagementIsUpdateBuildKey] = @NO;
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Test isUpdate");

	invocation.criteria = @{ @"is_update/build": @YES };
	engagementData[ATEngagementIsUpdateBuildKey] = @NO;
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Test isUpdate");

	invocation.criteria = @{ @"is_update/build": @NO };
	engagementData[ATEngagementIsUpdateBuildKey] = @YES;
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Test isUpdate");


	invocation.criteria = @{ @"is_update/build": @[[NSNull null]] };
	engagementData[ATEngagementIsUpdateBuildKey] = @NO;
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Should fail with invalid types.");
	invocation.criteria = @{ @"is_update/build": @{@"$gt": @"lajd;fl ajsd;flj"} };
	engagementData[ATEngagementIsUpdateBuildKey] = @NO;
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Should fail with invalid types.");
}

- (void)testInvokesVersion {
	NSMutableDictionary *engagementData = [NSMutableDictionary dictionary];

	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] initWithEngagementData:engagementData];

	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/version": @{@"$lte": @6} };
// Because we're not running a full backend for this test, the following doesn't work.
//	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Invokes version should default to 0 when not set.");

	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/version": @{@"$gte": @6} };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Invokes version should default to 0 when not set.");

	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/version": @{@"$lte": @6} };
	engagementData[ATEngagementInteractionsInvokesVersionKey] = @{ @"526fe2836dd8bf546a00000b": @1 };
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Invokes version");

	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/version": @{@"$lte": @6} };
	engagementData[ATEngagementInteractionsInvokesVersionKey] = @{ @"526fe2836dd8bf546a00000b": @7 };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Invokes version");
}

- (void)testInvokesBuild {

	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/build": @{@"$lte": @6} };

	NSMutableDictionary *engagementData = [NSMutableDictionary dictionary];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] initWithEngagementData:engagementData];
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
// Because we're not running a full backend for this test, the following doesn't work.
//	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Invokes build should default to 0 when not set.");

	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/build": @{@"$gte": @6} };
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Invokes build should default to 0 when not set.");

	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/build": @{@"$lte": @6} };
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
	engagementData[ATEngagementInteractionsInvokesBuildKey] = @{ @"526fe2836dd8bf546a00000b": @1 };
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Invokes build");

	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/build": @{@"$lte": @6} };
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
	engagementData[ATEngagementInteractionsInvokesBuildKey] = @{ @"526fe2836dd8bf546a00000b": @7 };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Invokes build");
}

- (void)testEnjoymentDialogCriteria {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	invocation.criteria = @{ @"$or": @[@{@"code_point/local#app#init/invokes/version": @{@"$gte": @10}},
		@{@"time_since_install/total": @{@"$gt": @864000}},
		@{@"code_point/local#app#testRatingFlow/invokes/total": @{@"$gt": @10}}],
		@"interactions/533ed97a7724c5457e00003f/invokes/version": @0 };
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");

	NSMutableDictionary *engagementData = [NSMutableDictionary dictionary];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] initWithEngagementData:engagementData];
	engagementData[ATEngagementCodePointsInvokesVersionKey] = @{ @"local#app#init": @9 };
	engagementData[ATEngagementInstallDateKey] = [NSDate dateWithTimeIntervalSinceNow:-863999];
	engagementData[ATEngagementCodePointsInvokesTotalKey] = @{ @"local#app#testRatingFlow": @9 };
	engagementData[ATEngagementInteractionsInvokesVersionKey] = @{ @"533ed97a7724c5457e00003f": @0 };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"The OR clauses are failing.");

	engagementData[ATEngagementCodePointsInvokesVersionKey] = @{ @"local#app#init": @11 };
	engagementData[ATEngagementInstallDateKey] = [NSDate dateWithTimeIntervalSinceNow:-863999];
	engagementData[ATEngagementCodePointsInvokesTotalKey] = @{ @"local#app#testRatingFlow": @9 };
	engagementData[ATEngagementInteractionsInvokesVersionKey] = @{ @"533ed97a7724c5457e00003f": @0 };
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"One of the OR clauses is true. The other ANDed clause is also true. Should work.");

	engagementData[ATEngagementCodePointsInvokesVersionKey] = @{ @"local#app#init": @11 };
	engagementData[ATEngagementInstallDateKey] = [NSDate dateWithTimeIntervalSinceNow:-863401];
	engagementData[ATEngagementCodePointsInvokesTotalKey] = @{ @"local#app#testRatingFlow": @11 };
	engagementData[ATEngagementInteractionsInvokesVersionKey] = @{ @"533ed97a7724c5457e00003f": @0 };
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"All of the OR clauses are true. The other ANDed clause is also true. Should work.");

	engagementData[ATEngagementInteractionsInvokesVersionKey] = @{ @"533ed97a7724c5457e00003f": @1 };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"All the OR clauses are true. The other ANDed clause is not true. Should fail.");
}

- (void)testCustomDataAndExtendedData {
	UIViewController *dummyViewController = [[UIViewController alloc] init];

	XCTAssertNoThrow([[ATConnect sharedConnection] engage:@"test_event" withCustomData:nil fromViewController:dummyViewController], @"nil custom data should not throw exception!");
	XCTAssertNoThrow([[ATConnect sharedConnection] engage:@"test_event" withCustomData:nil withExtendedData:nil fromViewController:dummyViewController], @"nil custom data or extended data should not throw exception!");
}

- (void)testCustomDeviceDataCriteria {
	[ATConnect sharedConnection].apiKey = @"123";

	[[ATConnect sharedConnection] removeCustomDeviceDataWithKey:@"test_version"];
	[[ATConnect sharedConnection] removeCustomDeviceDataWithKey:@"test_device_custom_data"];

	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	invocation.criteria = @{ @"device/custom_data/test_device_custom_data": @"test_value" };

	XCTAssertFalse([invocation criteriaAreMet], @"Criteria should not be met before adding custom data.");

	[[ATConnect sharedConnection] addCustomDeviceData:@"test_value" withKey:@"test_device_custom_data"];

	XCTAssertTrue([invocation criteriaAreMet], @"Criteria should be met after adding custom data.");

	invocation.criteria = @{ @"device/custom_data/test_device_custom_data": @"test_value",
		@"device/custom_data/test_version": @"4.5.1" };

	XCTAssertFalse([invocation criteriaAreMet], @"Criteria should not be met before adding custom data.");

	[[ATConnect sharedConnection] addCustomDeviceData:@"4.5.1" withKey:@"test_version"];

	XCTAssertTrue([invocation criteriaAreMet], @"Criteria should be met after adding custom data.");

	[[ATConnect sharedConnection] removeCustomDeviceDataWithKey:@"test_version"];
	[[ATConnect sharedConnection] removeCustomDeviceDataWithKey:@"test_device_custom_data"];
}

- (void)testCustomPersonDataCriteria {
	[ATConnect sharedConnection].apiKey = @"123";

	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	invocation.criteria = @{ @"person/custom_data/hair_color": @"black" };

	XCTAssertFalse([invocation criteriaAreMet], @"Criteria should not be met before adding custom data.");

	[[ATConnect sharedConnection] addCustomPersonData:@"black" withKey:@"hair_color"];

	XCTAssertTrue([invocation criteriaAreMet], @"Criteria should be met after adding custom data.");

	invocation.criteria = @{ @"person/custom_data/hair_color": @"black",
		@"person/custom_data/age": @"27" };

	XCTAssertFalse([invocation criteriaAreMet], @"Criteria should not be met before adding custom data.");

	[[ATConnect sharedConnection] addCustomPersonData:@"27" withKey:@"age"];

	XCTAssertTrue([invocation criteriaAreMet], @"Criteria should be met after adding custom data.");

	[[ATConnect sharedConnection] removeCustomPersonDataWithKey:@"age"];
	[[ATConnect sharedConnection] removeCustomPersonDataWithKey:@"hair_color"];
}

- (void)testCanShowInteractionForEvent {
	[ATConnect sharedConnection].apiKey = @"bogus_api_key"; // trigger creation of engagement backend

	ATInteractionInvocation *canShow = [[ATInteractionInvocation alloc] init];
	canShow.criteria = @{};
	canShow.interactionID = @"example_interaction_ID";

	ATInteractionInvocation *willNotShow = [[ATInteractionInvocation alloc] init];
	willNotShow.criteria = @{ @"cannot_parse_criteria": @"cannot_parse_criteria" };
	willNotShow.interactionID = @"example_interaction_ID";

	NSDictionary *targets = @{ [[ATInteraction localAppInteraction] codePointForEvent:@"canShow"]: @[canShow],
		[[ATInteraction localAppInteraction] codePointForEvent:@"cannotShow"]: @[willNotShow]
	};

	NSDictionary *interactions = @{ @"example_interaction_ID": [[ATInteraction alloc] init] };

	XCTAssertTrue([canShow criteriaAreMet], @"Invocation should be valid.");
	XCTAssertTrue([[ATConnect sharedConnection] canShowInteractionForEvent:@"canShow"], @"If invocation is valid, it will be shown for the next targeted event.");

	XCTAssertFalse([willNotShow criteriaAreMet], @"Invocation should not be valid.");
	XCTAssertFalse([[ATConnect sharedConnection] canShowInteractionForEvent:@"cannotShow"], @"If invocation is not valid, it will not be shown for the next targeted event.");
}

@end
