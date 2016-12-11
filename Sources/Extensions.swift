//
//  Extensions.swift
//  NewFan
//
//  Created by 赵少龙 on 2016/12/11.
//
//

import Foundation

extension String {
    func subStringAfterFirstCh() -> String {
        guard !self.isEmpty && self.characters.count > 1 else {
            return ""
        }
        var chs = self.characters
        chs.removeFirst()
        return String(chs)
    }
}
