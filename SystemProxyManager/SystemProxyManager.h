//
//  SystemProxyManager.h
//  SystemProxyManager
//
//  Created by Soumesh on 2019/12/19.
//  Copyright © 2019 Soumesh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

#define APP_NAME "uv2ray"

@interface SystemProxyManager : NSObject

bool SetSystemProxy(AuthorizationRef authRef, NSSet* interfaceList, NSString* address, NSNumber* port, bool usePAC);
bool clearProxy(AuthorizationRef authRef, NSSet* interfaceList);

@end
