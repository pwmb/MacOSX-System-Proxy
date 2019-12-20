//
//  main.m
//  ProxyPrefManager
//
//  Created by Soumesh on 2019/12/19.
//  Copyright © 2019 Soumesh. All rights reserved.
//
#define APP_NAME "uv2ray"
#define USAGE "usage: ./app [options]\noff\tProxy disable\non port\tSet Proxy for all the netowrk interface at given port\n"

#include "main.h"

int main(int argc, const char * argv[]) {
    if (argc < 2 || argc >3) {
        printf(USAGE);
        return 1;
    }
    @autoreleasepool {
        NSString *on_off = [NSString stringWithUTF8String:argv[1]];
        NSNumber *port;
        if (![on_off isEqualToString:@"on"] && ![on_off isEqualToString:@"off"]) {
            printf(USAGE);
            return 1;
        }
        if ([on_off isEqualToString:@"on"]) {
            if (argc != 3) {
                printf(USAGE);
                return 1;
            }
            //TODO - better way to convert char*(argv) to NSNumber*
            //https://stackoverflow.com/questions/1448804/how-to-convert-an-nsstring-into-an-nsnumber
            NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
            f.numberStyle = NSNumberFormatterDecimalStyle;
            NSString *portStr = [NSString stringWithUTF8String:argv[2]];
            port = [f numberFromString:portStr];
        }

        // Don't change this interface list this is exact name Apple returns for Interface.Hardware property
        NSSet *interfaceList = [NSSet setWithArray:@[@"Ethernet", @"AirPort"]];
        
        // Create AuthRef
        AuthorizationRef authRef;
        AuthorizationFlags authFlags;
        authFlags = kAuthorizationFlagDefaults | kAuthorizationFlagPreAuthorize | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights;
        OSStatus authErr = AuthorizationCreate(nil, kAuthorizationEmptyEnvironment, authFlags, &authRef);
        if (authErr != noErr || authRef == NULL) {
            NSLog(@"Failed to Authorize App to change system proxy settings %d", (int)authErr);
            return 1;
        }
        if ([on_off isEqualToString:@"off"]) {
            return SetUnsetSystemProxy(authRef, interfaceList, nil, nil, NO, YES) == NO ? 2 : 0;
        }
        return SetUnsetSystemProxy(authRef, interfaceList, @"127.0.0.1", port, NO, NO) == NO ? 2 : 0;
    }
    return 0;
}


bool SetUnsetSystemProxy(AuthorizationRef authRef, NSSet* interfaceList, NSString* address, NSNumber* port, bool usePAC, bool isClear){
    SCPreferencesRef scRef = SCPreferencesCreateWithAuthorization(nil, CFSTR(APP_NAME), nil, authRef);
    NSDictionary* preferences = SCPreferencesGetValue(scRef, kSCPrefNetworkServices);
    
    for (NSString *prefKey in [preferences allKeys]) {
        NSMutableDictionary *preference = [[preferences objectForKey:prefKey] mutableCopy];
        NSString *interfaceName = [preference valueForKeyPath:@"Interface.Hardware"];
        if ([interfaceList containsObject:interfaceName]) {
            NSDictionary *proxiesForNetworkInterface = [preference objectForKey:@"Proxies"];
            
            //Always clear the previously enabled proxy settings
            [proxiesForNetworkInterface setValue:@0 forKey:(NSString *)kCFNetworkProxiesProxyAutoConfigEnable];
            [proxiesForNetworkInterface setValue:@0 forKey:(NSString*)kCFNetworkProxiesSOCKSEnable];
            [proxiesForNetworkInterface setValue:@0 forKey:(NSString*)kCFNetworkProxiesHTTPEnable];
            [proxiesForNetworkInterface setValue:@0 forKey:(NSString*)kCFNetworkProxiesHTTPSEnable];
            
            if (isClear == NO) {
                if (usePAC == YES) {
                    //Enable proxy to pac server
                    [proxiesForNetworkInterface setValue:@1 forKey:(NSString *)kCFNetworkProxiesProxyAutoConfigEnable];
                    [proxiesForNetworkInterface setValue:[NSString stringWithFormat:@"http://%@:%@/pac", address, port] forKey:(NSString *)kCFNetworkProxiesProxyAutoConfigURLString];
                } else {
                    //Enable Socks Proxy
                    [proxiesForNetworkInterface setValue:@1 forKey:(NSString*)kCFNetworkProxiesSOCKSEnable];
                    [proxiesForNetworkInterface setValue:port forKey:(NSString*)kCFNetworkProxiesSOCKSPort];
                    [proxiesForNetworkInterface setValue:address forKey:(NSString*)kCFNetworkProxiesSOCKSProxy];
                    
                    //Enable HTTP Proxy
                    [proxiesForNetworkInterface setValue:@1 forKey:(NSString*)kCFNetworkProxiesHTTPEnable];
                    [proxiesForNetworkInterface setValue:port forKey:(NSString*)kCFNetworkProxiesHTTPPort];
                    [proxiesForNetworkInterface setValue:address forKey:(NSString*)kCFNetworkProxiesHTTPProxy];
                    
                    //Enable HTTPS Proxy
                    [proxiesForNetworkInterface setValue:@1 forKey:(NSString*)kCFNetworkProxiesHTTPSEnable];
                    [proxiesForNetworkInterface setValue:port forKey:(NSString*)kCFNetworkProxiesHTTPSPort];
                    [proxiesForNetworkInterface setValue:address forKey:(NSString*)kCFNetworkProxiesHTTPSProxy];
                    
                }
            }
            
            BOOL isOk = SCPreferencesSetValue(scRef, (__bridge CFStringRef)prefKey, (__bridge CFPropertyListRef)preference);
            if (!isOk) {
                NSLog(@"Failed to set preference for %@ having key %@", interfaceName, prefKey);
                return isOk;
            }
        }
    }
    
    BOOL isOk = SCPreferencesCommitChanges(scRef);
    if (!isOk) {
        printf("Unable to commit changes, maybe due to permission error.\n");
        return isOk;
    }
    
    isOk = SCPreferencesApplyChanges(scRef);
    if (!isOk) {
        printf("Unable to apply changes, maybe due to permission error.\n");
        return isOk;
    }
    
    SCPreferencesSynchronize(scRef);
    printf("Success!\n");
    return YES;
}
