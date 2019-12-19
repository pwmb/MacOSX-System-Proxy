//
//  SystemProxyManager.m
//  SystemProxyManager
//
//  Created by Soumesh on 2019/12/19.
//  Copyright © 2019 Soumesh. All rights reserved.
//

#import "SystemProxyManager.h"

@implementation SystemProxyManager

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
        NSLog(@"Unable to commit changes");
        return isOk;
    }
    
    isOk = SCPreferencesApplyChanges(scRef);
    if (!isOk) {
        NSLog(@"Unable to apply changes");
        return isOk;
    }
    
    SCPreferencesSynchronize(scRef);
    
    return YES;
}

bool SetSystemProxy(AuthorizationRef authRef, NSSet* interfaceList, NSString* address, NSNumber* port, bool usePAC) {
    return SetUnsetSystemProxy(authRef, interfaceList, address, port, usePAC, NO);
}

bool clearProxy(AuthorizationRef authRef, NSSet* interfaceList) {
    return SetUnsetSystemProxy(authRef, interfaceList, nil, nil, NO, YES);
}

@end
