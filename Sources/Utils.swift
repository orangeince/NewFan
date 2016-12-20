//
//  Utils.swift
//  NewFan
//
//  Created by 赵少龙 on 2016/12/11.
//
//

import Foundation

struct RegexHelper {
    let regex: RegularExpression
    
    init(_ pattern: String) throws {
        try regex = RegularExpression(pattern: pattern, options: [])
    }
    
    func match(input: String) -> Bool {
        let matchedCount = regex.numberOfMatches(in: input,
                                                 options: [],
                                                 range: NSMakeRange(0, input.utf16.count))
        return matchedCount > 0
    }
}

infix operator =~: AdditionPrecedence

func =~(lhs: String, rhs: String) -> Bool {
    do {
        //print("lhs: \(lhs), rhs: \(rhs)")
        return try RegexHelper(rhs).match(input: lhs)
    } catch _ {
        return false
    }
}

func splitCommand(str: String) -> (Int, String) {
    guard !str.isEmpty else {
        return (0, "")
    }
    let signCh = str.characters.first!
    return (signCh == "-" ? -1 : 1, str.subStringAfterFirstCh())
}
