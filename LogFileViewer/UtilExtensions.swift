//
//  UtilExtensions.swift
//  LogFileViewer//  Created by Mohankumar on 01/03/18.
//  Copyright © 2018 Mohankumar. All rights reserved.
//

import Foundation
import UIKit


extension Array where Iterator.Element == [String: Any]{
    mutating func sortByKey(key: String)->[Any]{
        self = self.sorted{
            (dictOne, dictTwo) -> Bool in
            if let firstString : Int = dictOne[key] as? Int,let secondString : Int = dictTwo[key] as? Int{
                return firstString < secondString
            }
            else if let firstString : String = dictOne[key] as? String,let secondString : String = dictTwo[key] as? String{
                if firstString.isNumber(){
                    return Int(firstString)! < Int(secondString)!
                }
                return firstString < secondString
            }
            return true
        }
        return self
    }
}

extension Dictionary{
    func collectionIndices()->[Int]{
        var indices : [Int] = []
        for (index, key) in self.keys.enumerated(){
            if (self[key] as? Array<Any>) != nil{
                indices.append(index)
            }
            else if (self[key] as? Dictionary<String,Any>) != nil{
                indices.append(index)
            }
        }
        return indices
    }
    
    func collectionTypes()->[Any]{
        return self.filter{($0.value as? Dictionary<String,Any>) != nil || ($0.value as? Array<Any>) != nil}
    }
    
    func valueTypes()->Dictionary<String,Any>{
        return self.filter{($0.value as? String) != nil || ($0.value as? NSNumber) != nil} as! Dictionary<String, Any>
    }
    
    func minSortableIntValueKey()->String?{
        var selectedKey : String?
        var number : Int64 = 0
        for (index, key) in self.keys.enumerated(){
            if let val = self[key] as? String{
                if val.isNumber(){
                    if index == 0 || number == 0{
                        number = Int64(val)!
                    }
                    if Int(val)! <= number{
                        number = Int64(val)!
                        selectedKey = key as? String
                    }
                }
            }
            if let val = self[key] as? NSNumber{
                if index == 0 || number == 0{
                    number = val.int64Value
                }
                if val.int64Value <= number{
                    number = val.int64Value
                    selectedKey = key as? String
                }
            }
        }
        return selectedKey
    }
    
    func maxSortableIntValueKey()->String?{
        var selectedKey : String?
        var number : Int64 = 0
        for (index, key) in self.keys.enumerated(){
            if let val = self[key] as? String{
                if val.isNumber(){
                    if index == 0 || number == 0{
                        number = Int64(val)!
                    }
                    if Int(val)! >= number{
                        number = Int64(val)!
                        selectedKey = key as? String
                    }
                }
            }
            if let val = self[key] as? NSNumber{
                if index == 0 || number == 0{
                    number = val.int64Value
                }
                if val.int64Value >= number{
                    number = val.int64Value
                    selectedKey = key as? String
                }
            }
        }
        return selectedKey
    }
}

extension String {
    
    func split(regex pattern: String) -> [String] {
        guard let re = try? NSRegularExpression(pattern: pattern, options: [])
            else { return [] }
        let nsString = self as NSString // needed for range compatibility
        let seperator = "###$###"
        let stop = "\(seperator)$0"
        let modifiedString = re.stringByReplacingMatches(
            in: self,
            options: [],
            range: NSRange(location: 0, length: nsString.length),
            withTemplate: stop)
        
        return modifiedString.components(separatedBy: seperator)
    }
    
    func splitAfter(regex pattern: String) -> [String] {
        guard let re = try? NSRegularExpression(pattern: pattern, options: [])
            else { return [] }
        let nsString = self as NSString // needed for range compatibility
        let seperator = "###$###"
        let stop = "$0\(seperator)"
        let modifiedString = re.stringByReplacingMatches(
            in: self,
            options: [],
            range: NSRange(location: 0, length: nsString.length),
            withTemplate: stop)
        return modifiedString.components(separatedBy: seperator)
    }
    
    func date()->Date?{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss." //Your date format
        dateFormatter.timeZone = TimeZone.init(secondsFromGMT: 0)
        let date = dateFormatter.date(from: self) //according to date format your date string
        return date
    }
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
        
        return ceil(boundingBox.width)
    }
    
    func isNumber() -> Bool {
        let numberCharacters = NSCharacterSet.decimalDigits.inverted
        return !self.isEmpty && self.rangeOfCharacter(from: numberCharacters) == nil
    }
}


extension Date{
    func dateString()->String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss" //Your date format
        dateFormatter.timeZone = TimeZone.init(secondsFromGMT: 0)
        let dateString = dateFormatter.string(from: self) //according to date format your date string
        return dateString
    }
}

extension Array where Element : Equatable {
    var unique: [Element] {
        var uniqueValues: [Element] = []
        forEach { item in
            if !uniqueValues.contains(item) {
                uniqueValues += [item]
            }
        }
        return uniqueValues
    }
}

func saveFile(data : Data){
    let filename = "Sample"
    guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
    let fileUrl = documentDirectoryUrl.appendingPathComponent("\(filename.components(separatedBy: "/").last ?? filename).json")
    try! data.write(to:fileUrl, options: [])
}
