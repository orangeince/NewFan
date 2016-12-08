//
//  FanWaiter.swift
//  NewFan
//
//  Created by 赵少龙 on 2016/12/8.
//
//

import Foundation

class FanWaiter {
    static func handleFanPlanWith(commandStr: String, userName: String) -> String {
        return "\(userName): \(commandStr)"
    }
}
