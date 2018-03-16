//
//  LogFileParser.swift
//  LogFileViewer//  Created by Mohankumar on 01/03/18.
//  Copyright © 2018 Mohankumar. All rights reserved.
//

import Foundation

enum LogType : String {
    case Info
    case URL
    case Request
    case RequestXML
    case Response
    case ResponseXML
    case Error
    static let allValues = [Info, URL, Request,Response,RequestXML,ResponseXML,Error]
}

struct LogMessage{
    var time : Date
    var logType : LogType
    var message : String
    var wholeContent : String
    var json : Dictionary<String, Any>?
}

enum ParserStatus{
    case success
    case failure(error : String)
}

enum ParserError : Error{
    case FileNotFound
}

class LogParser{
    
    private(set) var logMessages : [LogMessage] = []
    private(set) var log = [String:[LogMessage]]()
    public var logKeys :[String]{
        get {
            return self.log.keys.sorted()
        }
    }
    
    func generateLog(sorted: [LogMessage],completion: @escaping ()->()){
        let datesArray = sorted.flatMap { $0.time} // return array of date
        self.log = [String:[LogMessage]]()
        datesArray.forEach {
            let dateKey = $0
            let filterArray = sorted.filter { $0.time == dateKey }
            self.log[$0.dateString()] = filterArray
        }
        completion()
    }
    
    fileprivate func parseLogString(_ parsedString: String?) {
        let dateRegEx = "\\d{4}[-/.]\\d{1,2}[-/.]\\d{1,2}"
        let timeRegEx = "\\d{2}:\\d{2}:\\d{2}"
        let pattern = "\(dateRegEx)\\s+\(timeRegEx)[^\"]"
        
        let array = (parsedString?.split(regex: pattern))!
        //                self.log = array
        var url = ""
        var req = Dictionary<String, Any>()
        logMessages = []
        for logMessage in array{
            var logMessageComponents = logMessage.splitAfter(regex: pattern)
            var dateString = logMessageComponents[0]
            if dateString.indices.count > 0{
                dateString.remove(at: dateString.index(before: dateString.endIndex))
            }
            if let dateTime = dateString.date(){
                if logMessageComponents.count > 1 {
                    
                    let jsonRegex = "\\{.*\\}"
                    var trimmed = logMessageComponents[1].trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
                    trimmed = trimmed.replacingOccurrences(of: "\n", with: "")
                    let array = (trimmed.split(regex: jsonRegex))
                    if array.count>1{
                        let message = array[1]
                        
                        if let data = message.data(using: .utf8){
                            do{
                                let json = try JSONSerialization.jsonObject(with: data, options:.mutableLeaves)
                                
                                if message.contains("errorCode"){
                                    if var jsonDict  = json as? Dictionary<String, Any>{
                                        jsonDict["url"] = url
                                        jsonDict["req"] = req
                                        logMessages.append(LogMessage.init(time: dateTime, logType: .Response, message: url, wholeContent: logMessage, json: jsonDict))
                                    }
                                }
                                else{
                                    req = json as! [String : Any]
                                    if var jsonDict  = json as? Dictionary<String, Any>{
                                        jsonDict["url"] = url
                                        logMessages.append(LogMessage.init(time: dateTime, logType: .Request, message: url, wholeContent: logMessage, json: jsonDict))
                                    }
                                }
                            }
                            catch let error{
                                print(error.localizedDescription)
                                logMessages.append(LogMessage.init(time: dateTime, logType: .Error, message: message, wholeContent: logMessage, json: nil))
                                continue
                            }
                        }
                    }
                    else{
                        let jsonRegex = "\\<.*\\>"
                        var trimmed = logMessageComponents[1].trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
                        trimmed = trimmed.replacingOccurrences(of: "\n", with: "")
                        let array = (trimmed.split(regex: jsonRegex))
                        if array.count>1{
                            let message = array[1]
                            if let data = message.data(using: .utf8){
                                do{
                                    let xml = XML.parse(data)
                                    let array =  self.convertXMLToDict(xmlAny: xml.all!)
                                    let dict  = convertArrayOrDictToAny(nameOfArrayIfArrayExists: "Root", array: array)
                                    let data = try! JSONSerialization.data(withJSONObject: dict, options: [])
                                    let json = try JSONSerialization.jsonObject(with: data, options:.mutableLeaves)
                                    
                                    if message.contains("errorCode"){
                                        if var jsonDict  = json as? Dictionary<String, Any>{
                                            jsonDict["url"] = url
                                            jsonDict["req"] = req
                                            logMessages.append(LogMessage.init(time: dateTime, logType: .ResponseXML, message: url, wholeContent: logMessage, json: jsonDict))
                                        }
                                    }
                                    else{
                                        req = json as! [String : Any]
                                        if var jsonDict  = json as? Dictionary<String, Any>{
                                            jsonDict["url"] = url
                                            logMessages.append(LogMessage.init(time: dateTime, logType: .RequestXML, message: url, wholeContent: logMessage, json: jsonDict))
                                        }
                                    }
                                }
                                catch let error{
                                    print(error.localizedDescription)
                                    logMessages.append(LogMessage.init(time: dateTime, logType: .Error, message: message, wholeContent: logMessage, json: nil))
                                    continue
                                }
                            }
                        }
                        else{
                            let jsonRegex = "((https|http)://)((\\w|-)+)(([.]|[/])((\\w|-)+))+"
                            var trimmed = logMessageComponents[1].trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
                            trimmed = trimmed.replacingOccurrences(of: "\n", with: "")
                            let array = (trimmed.split(regex: jsonRegex))
                            if array.count>1{
                                let message =  array[1]
                                url = message
                                logMessages.append(LogMessage.init(time: dateTime, logType: .URL, message: message, wholeContent: logMessage, json: nil))
                            }
                            else{
                                logMessages.append(LogMessage.init(time: dateTime, logType: .Info, message: logMessageComponents[1],wholeContent: logMessage, json: nil))
                            }
                        }
                    }
                }
            }
        }
    }
    
    func convertArrayOrDictToAny(nameOfArrayIfArrayExists : String,array: Any)->Any{
        var dict  = [nameOfArrayIfArrayExists:array]
        if let isDict = array as? Dictionary<String,Any> {
            dict = [:]
            for (_,element) in isDict.enumerated(){
                dict[element.key] = element.value
            }
        }
        return dict
    }
    
    func parseLogFile(completion: @escaping (ParserStatus)->()){
        if let path = Bundle.main.path(forResource: "itunes", ofType: "log"){
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let parsedString = String.init(data: data, encoding: .utf8)
                parseLogString(parsedString)
                completion(.success)
            } catch let error{
                // handle error
                completion(.failure(error: error.localizedDescription))
                print("LogParser Error",error.localizedDescription)
            }
        }
        else{
            completion(.failure(error: "File Not found"))
        }
    }
    
    func convertXMLToDict( xmlAny : [Any])->Any{
        var array : [Dictionary<String, Any>] = []
        if let xml : [XML.Element] = xmlAny as? [XML.Element]{
            for elt in xml.enumerated(){
                var dict : Dictionary<String, Any> = [:]
                dict[elt.element.name] = elt.element.text
                if elt.element.attributes.keys.count > 0{
                    var attrDict : Dictionary<String, Any> = [:]
                    for (key,value) in elt.element.attributes{
                        attrDict[key] = value
                    }
                    dict["attributes"] = attrDict
                }
                if elt.element.childElements.count > 0 {
                    var child = [Any]()
                    for childElt in elt.element.childElements{
                        if dict.keys.contains(childElt.name){
                            if let _ = dict[childElt.name] as? Dictionary<String,Any> {
//                                childArray = alreadyArray
                                let resulstantArray =  convertXMLToDict(xmlAny: [childElt])
                                child = [convertArrayOrDictToAny(nameOfArrayIfArrayExists: "\(childElt.name)-\(child.count+1)", array: resulstantArray) as! [String : Any]]
                            }
                            else if let isArrayExists = dict[childElt.name] as? [Dictionary<String, Any>]{
                                let resulstantArray =  convertXMLToDict(xmlAny: [childElt])
                                child = isArrayExists
                                child.append(convertArrayOrDictToAny(nameOfArrayIfArrayExists: "\(childElt.name)-\(child.count+1)", array: resulstantArray) as! [String : Any])
                            }
                            dict[childElt.name] = child
                        }
                        else{
                            let resulstantArray =  convertXMLToDict(xmlAny: [childElt])
                            dict[childElt.name] = convertArrayOrDictToAny(nameOfArrayIfArrayExists: "\(childElt.name)", array: resulstantArray) as! [String : Any]
                        }
                    }
                }
                array.append(dict)
            }
        }
        
        return array.count > 1 ? array : array[0]
    }
    
    func parseString(parsedString : String,completion: @escaping (ParserStatus)->()){
        parseLogString(parsedString)
        completion(.success)
    }
}
