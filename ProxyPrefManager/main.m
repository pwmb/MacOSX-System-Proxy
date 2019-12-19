//
//  main.m
//  ProxyPrefManager
//
//  Created by Soumesh on 2019/12/19.
//  Copyright © 2019 Soumesh. All rights reserved.
//

#include "main.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSSet *interfaceList = [NSSet setWithArray:@[@"Wifi", @"Ethernet"]];
        
        AuthorizationRef authRef;
        AuthorizationFlags authFlags;
        authFlags = kAuthorizationFlagDefaults | kAuthorizationFlagPreAuthorize | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights;
        
        OSStatus authErr = AuthorizationCreate(nil, kAuthorizationEmptyEnvironment, authFlags, &authRef);
        if (authErr != noErr || authRef == NULL) {
            NSLog(@"Failed to Authorize App to change system proxy settings %d", (int)authErr);
            return 1;
        }
        
        if (argc == 1) {
            return clearProxy(authRef, interfaceList);
        }
        return SetSystemProxy(authRef, interfaceList, @"127.0.0.2", @5698, false);
    }
    return 0;
}
