//
//  Descriptions.swift
//  RhythmicRebellion
//
//  Created by Andrey Ivanov on 5/9/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct DeepDescription {
    
    static func description(any: Any) -> String {
        
        if let any = any as? CustomStringConvertible & CustomDescription {
            return any.description
        }
        
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
                    string += description(any: property.value)
                } else {
                    string += "\(property.label!): \(description(any: property.value))"
                }
                
                string += (index < properties.count - 1 ? ", " : "")
            }
            
            return string + ")"
        case .collection, .set:
            if properties.count == 0 { return "[]" }
            
            var string = "["
            
            for (index, property) in properties.enumerated() {
                string += indentedString(description(any: property.value) + (index < properties.count - 1 ? ",\r" : ""))
            }
            
            return string + "\r]"
        case .dictionary:
            
            if properties.count == 0 { return "[:]" }
            
            if let any = any as? CustomDictionaryDescription {
                return any.prettyDescription
            }
            
            if let any = any as? CustomOptionalDictionaryDescription {
                return any.prettyDescription
            }
            
            var string = "["
            
            for (index, property) in properties.enumerated() {
                let pair = Array(Mirror(reflecting: property.value).children)
                
                string += indentedString("\(description(any: pair[0].value)): \(description(any: pair[1].value))" + (index < properties.count - 1 ? ",\r" : ""))
            }
            
            return string + "\r]"
        case .enum:
            
            if let any = any as? CustomStringConvertible {
                return any.description
            }
            
            if properties.count == 0 { return "\(mirror.subjectType)." +  "(any)" }
            
            var string = "\(mirror.subjectType).\(properties.first!.label!)"
            
            let associatedValueString = description(any: properties.first!.value)
            
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
                string += indentedString("\(property.label!): \(description(any: property.value))" + (index < properties.count - 1 ? ",\r" : ""))
            }
            
            return string + "\r}"
        case .optional: fatalError("deepUnwrap must have failed...")
        }
    }
    
    fileprivate static func deepUnwrap(any: Any) -> Any? {
        
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
}

extension AppState: CustomStringConvertible {
    public var description: String {
        return DeepDescription.description(any: self)
    }
}

extension PlayerState: CustomStringConvertible {
    public var description: String {
        return DeepDescription.description(any: self)
    }
}

extension LinkedPlaylist: CustomStringConvertible {
    public var description: String {
        return DeepDescription.description(any: self)
    }
}

protocol CustomDescription {}
protocol CustomDictionaryDescription {
    var prettyDescription: String {get}
}

protocol CustomOptionalDictionaryDescription {
    var prettyDescription: String {get}
}

extension Track: CustomStringConvertible, CustomDescription {
    public var description: String {
        return "<\(type(of: self))>: id: \(id), name: \(name)"
    }
}

extension DefaultAudioFile: CustomStringConvertible, CustomDescription {
    public var description: String {
        return "<\(type(of: self))>: duration: \(duration), urlString: \(urlString)"
    }
}

extension Country: CustomStringConvertible, CustomDescription {
    public var description: String {
        return "<\(type(of: self))>: id: \(id), code: \(code), name:\(name)"
    }
}

extension LinkedPlaylist.ReduxView: CustomDictionaryDescription {
    var prettyDescription: String {
        return "{" +  self.compactMap({
            "\r  \($0) -> \($1.sorted(by: { $0.0.rawValue < $1.0.rawValue }).compactMap({"[\($0) : \(DeepDescription.description(any:$1 as Any))]"}).joined(separator: ", "))"
        }).joined(separator: "") + "\r}"
    }
}

extension LinkedPlaylist.NullableReduxView: CustomOptionalDictionaryDescription {
    var prettyDescription: String {
        return "{" +  self.compactMap({
            "\r  \($0) -> \(DeepDescription.description(any: $1?.sorted(by: { $0.0.rawValue < $1.0.rawValue }).compactMap({"[\($0) : \(DeepDescription.description(any:$1 as Any))]"}).joined(separator: ", ") as Any))"
        }).joined(separator: "") + "\r}"
    }
}

extension OrderedTrack: CustomStringConvertible {
    public var description: String {
        return DeepDescription.description(any: self)
    }
}

extension PlayerConfig: CustomStringConvertible {
    public var description: String {
        return DeepDescription.description(any: self)
    }
}

extension User: CustomStringConvertible {
    public var description: String {
        return DeepDescription.description(any: self)
    }
}

extension UserProfile: CustomStringConvertible {
    public var description: String {
        return DeepDescription.description(any: self)
    }
}
extension PlayerState.CurrentItem: CustomStringConvertible {
    public var description: String {
        return DeepDescription.description(any: self)
    }
}

extension PlayerState.ReduxViewPatch: CustomStringConvertible {
    public var description: String {
        return DeepDescription.description(any: self)
    }
}

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
