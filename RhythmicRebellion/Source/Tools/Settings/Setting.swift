//
//  Setting.swift
//     
//
//  Created by Vlad Soroka on 10/25/16.
//  Copyright © 2016    All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol UserDefaultsStorable {
    
    func store(for key: String)
    init?(key: String)

}

struct Setting<T: UserDefaultsStorable> {
    
    var value: T {
        get {
            return variableValue.value
        }
        set {
            variableValue.accept(newValue)
        }
        
    }
    
    var observable: Observable<T> {
        return variableValue.asObservable()
    }
    
    fileprivate let variableValue: BehaviorRelay<T>
    fileprivate let bag = DisposeBag()
    
    init (key: String, initialValue: T) {
        
        variableValue = BehaviorRelay( value: T(key: key) ?? initialValue )
        
        variableValue.asObservable()
            .subscribe(onNext: { (newValue) in
                
                newValue.store(for: key)
                UserDefaults.standard.synchronize()
                
            })
            .disposed(by: bag)
    }
    
}


extension Bool : UserDefaultsStorable {
    
    func store(for key: String) {
        UserDefaults.standard.set(self, forKey: key)
    }
    
    init?(key: String) {
        
        guard let _ = UserDefaults.standard.object(forKey: key) else { return nil }
        
        self = UserDefaults.standard.bool(forKey: key)
    }
    
}

extension String : UserDefaultsStorable {
    
    func store(for key: String) {
        UserDefaults.standard.set(self, forKey: key)
    }
    
    init?(key: String) {
        
        guard let str = UserDefaults.standard.string(forKey: key) else { return nil }
        
        self = str
    }
    
}

extension Optional: UserDefaultsStorable where Wrapped : UserDefaultsStorable {
    
    func store(for key: String) {
        
        switch self {
        case .none:
            UserDefaults.standard.set(nil, forKey: key)
        case .some(let x):
            x.store(for: key)
        }
        
    }
    
    init?(key: String) {
        self = Wrapped(key: key)
    }
    
}

extension Data : UserDefaultsStorable {
    
    func store(for key: String) {
        UserDefaults.standard.set(self, forKey: key)
    }
    
    init?(key: String) {
        
        guard let x = UserDefaults.standard.data(forKey: key) else { return nil }
        
        self = x
    }
    
}

extension Date : UserDefaultsStorable {
    
    func store(for key: String) {
        UserDefaults.standard.set(self, forKey: key)
    }
    
    init?(key: String) {
        
        guard let x = UserDefaults.standard.object(forKey: key) as? Date else { return nil }
        
        self = x
    }
    
}

extension Encodable where Self : UserDefaultsStorable {
    
    func store(for key: String) {
        
        let x: Data
        do {
            x = try JSONEncoder().encode(self)
        }
        catch(let e) {
            fatalError("Error encoding object \(self). Details \(e)")
        }
        
        UserDefaults.standard.setValue(x, forKey: key)
    }
    
}

extension Decodable where Self: UserDefaultsStorable {
    
    init?(key: String) {
        
        guard let x = UserDefaults.standard.data(forKey: key) else {
            return nil }
            
        
        let t: Self
        do {
            t = try JSONDecoder().decode(Self.self, from: x)
        }
        catch(let e) {
            fatalError("Error decoding object \(x) for key \(key). Details \(e)")
        }
        
        self = t
        
    }
    
}

extension Array: UserDefaultsStorable where Element: Codable {}


extension Dictionary: UserDefaultsStorable where Key == String, Value == Int {
    
    func store(for key: String) {
        UserDefaults.standard.set(self, forKey: key)
    }
    
    init?(key: String) {
        guard let x = UserDefaults.standard.value(forKey: key) as? [Key: Value]
            else { return nil }
        
        self = x
    }
    
}
