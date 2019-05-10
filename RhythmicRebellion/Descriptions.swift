//
//  Descriptions.swift
//  RhythmicRebellion
//
//  Created by Andrey Ivanov on 5/9/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

extension CustomStringConvertible {
    public var description: String {
        return deepDescription(any: self)
    }
}

func deepDescription(any: Any) -> String {
    
    guard let any = deepUnwrap(any: any) else { return "nil" }
    if any is Void { return "Void" }
    
    if let int = any as? Int {
        return String(int)
    } else if let double = any as? Double {
        return String(double)
    } else if let float = any as? Float {
        return String(float)
    } else if let bool = any as? Bool {
        return String(bool)
    } else if let string = any as? String {
        return "\"\(string)\""
    }
    
    let tab = "  "
    let indentedString: (String) -> String = {
        $0.components(separatedBy: .newlines).map { $0.isEmpty ? "" : "\r\(tab)\($0)" }.joined(separator: "")
    }
    
    let mirror = Mirror(reflecting: any)
    
    let properties = Array(mirror.children)
    
    guard let displayStyle = mirror.displayStyle else {
        return "\(any)"
    }
    
    switch displayStyle {
    case .tuple:
        if properties.count == 0 { return "()" }
        
        var string = "("
        
        for (index, property) in properties.enumerated() {
            if property.label!.first! == "." {
                string += deepDescription(any: property.value)
            } else {
                string += "\(property.label!): \(deepDescription(any: property.value))"
            }
            
            string += (index < properties.count - 1 ? ", " : "")
        }
        
        return string + ")"
    case .collection, .set:
        if properties.count == 0 { return "[]" }
        
        var string = "["
        
        for (index, property) in properties.enumerated() {
            string += indentedString(deepDescription(any: property.value) + (index < properties.count - 1 ? ",\r" : ""))
        }
        
        return string + "\r]"
    case .dictionary:
        if properties.count == 0 { return "[:]" }
        
        var string = "["
        
        for (index, property) in properties.enumerated() {
            let pair = Array(Mirror(reflecting: property.value).children)
            
            string += indentedString("\(deepDescription(any: pair[0].value)): \(deepDescription(any: pair[1].value))" + (index < properties.count - 1 ? ",\r" : ""))
        }
        
        return string + "\r]"
    case .enum:

        if let any = any as? CustomStringConvertible {
            return any.description
        }
        
        if properties.count == 0 { return "\(mirror.subjectType)." +  "(any)" }
        
        var string = "\(mirror.subjectType).\(properties.first!.label!)"
        
        let associatedValueString = deepDescription(any: properties.first!.value)
        
        if associatedValueString.first! == "(" {
            string += associatedValueString
        } else {
            string += "(\(associatedValueString))"
        }
        
        return string
    case .struct, .class:
        if let any = any as? CustomDebugStringConvertible {
            return any.debugDescription
        }
        
        if properties.count == 0 { return "\(any)" }
        
        var string = "<\(mirror.subjectType)"
        
        if displayStyle == .class, let object = any as AnyObject? {
            string += ": \(Unmanaged<AnyObject>.passUnretained(object).toOpaque())"
        }
        
        string += "> {"
        
        for (index, property) in properties.enumerated() {
            string += indentedString("\(property.label!): \(deepDescription(any: property.value))" + (index < properties.count - 1 ? ",\r" : ""))
        }
        
        return string + "\r}"
    case .optional: fatalError("deepUnwrap must have failed...")
    }
}

func deepUnwrap(any: Any) -> Any? {
    
    let mirror = Mirror(reflecting: any)
    if mirror.displayStyle != .optional { return any }
    if let child = mirror.children.first, child.label == "Some" {
        return deepUnwrap(any: child.value)
    }
    
    if let value = any as Optional {
        return "\(value as AnyObject)"
    }
    
    return nil
}

extension AppState: CustomStringConvertible {}
extension PlayerState: CustomStringConvertible {}
extension LinkedPlaylist: CustomStringConvertible {}
extension Track: CustomStringConvertible {
    public var description: String {
        return "Track"
    }
}
extension OrderedTrack: CustomStringConvertible {}
extension PlayerConfig: CustomStringConvertible {}
extension User: CustomStringConvertible {}
extension UserProfile: CustomStringConvertible {}
extension PlayerState.CurrentItem: CustomStringConvertible {}
extension PlayerState.ReduxViewPatch: CustomStringConvertible {}

extension LinkedPlaylist.ViewKey: CustomStringConvertible{
    var description: String {
        switch self {
        case .id: return ".id"
        case .hash: return ".hash"
        case .previous: return ".previous"
        case .next: return ".next"
        }
    }
}
