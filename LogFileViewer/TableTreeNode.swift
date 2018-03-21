//
//  TableTreeNode.swift
//  LogFileViewer
//
//  Created by Mohankumar on 21/03/18.
//  Copyright © 2018 Mohankumar. All rights reserved.
//

import Foundation

//
//  TableNode.swift
//  MultilevelTable
//
//  Created by Mohankumar on 15/02/18.
//  Copyright © 2018 Learning. All rights reserved.
//

import Foundation


class TableTreeNode:Hashable{
    var hashValue: Int{
        if let hasParent = parent{
            return hasParent.level*100+index+level*10+index
        }
        return level*10+index
    }
    
    static func ==(lhs: TableTreeNode, rhs: TableTreeNode) -> Bool {
        return lhs.level == rhs.level && lhs.parent == rhs.parent && lhs.index == rhs.index
    }
    
    var value: String
    var level: Int
    var index : Int
    var isExpanded: Bool
    var children: [TableTreeNode] = []
    weak var parent: TableTreeNode?
    
    init(value: String, level: Int, index : Int, isExpanded : Bool) {
        self.value = value
        self.level = level
        self.isExpanded = isExpanded
        self.index = index
    }
    
    func add(child: TableTreeNode) {
        children.append(child)
        child.parent = self
    }
}


extension TableTreeNode: CustomStringConvertible {
    // 2
    var description: String {
        // 3
        var text = "\(value)"
        
        // 4
        if !children.isEmpty {
            text += " \n{" + children.map { $0.description }.joined(separator: ", ") + "} \n"
        }
        return text
    }
}
