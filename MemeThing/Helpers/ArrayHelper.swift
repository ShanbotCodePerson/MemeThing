//
//  ArrayHelper.swift
//  MemeThing
//
//  Created by Shannon Draeker on 7/5/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation

// A function to append something to an array without letting it be a duplicate
extension Array where Element: Equatable {
    mutating func uniqueAppend(_ element: Element) {
        if !self.contains(element) { self.append(element) }
    }
}

// A function to append something to an array without letting it be a duplicate
//extension Array where Element: Hashable {
//    mutating func uniqueAppend(_ element: Element) {
//        var currentList = self
//        currentList.append(element)
//        self = Array(Set(currentList))
//    }
//}
