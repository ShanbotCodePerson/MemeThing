//
//  Reachability.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/18/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import SystemConfiguration

class Reachability {
    
    private static let reachability = SCNetworkReachabilityCreateWithName(nil, "www.google.com")
    
    static func checkReachable() -> Bool {
        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(self.reachability!, &flags)
        
        if isNetworkReachable(with: flags) { return true }
        else if !isNetworkReachable(with: flags) {  return false }
        return false
    }
    
    private static func isNetworkReachable(with flags: SCNetworkReachabilityFlags) -> Bool {
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
        let canConnectWithoutUserInteraction = canConnectAutomatically && !flags.contains(.interventionRequired)
        return isReachable && (!needsConnection || canConnectWithoutUserInteraction)
    }
}
