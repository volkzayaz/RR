//
//
//   
//
//  Created by Vlad Soroka on 7/22/17.
//  Copyright © 2017   All rights reserved.
//

import Alamofire
import RxSwift

protocol BaseNetworkRouter : URLRequestConvertible, ReactiveCompatible {
    
    func personilisedRequest(method: Alamofire.HTTPMethod,
                           path: String,
                           params: Parameters?,
                           encoding: ParameterEncoding,
                           headers: HTTPHeaders?) -> URLRequest
     
    func anonymousRequest(method: Alamofire.HTTPMethod,
                          path: String,
                          params: Parameters?,
                          encoding: ParameterEncoding,
                          headers: HTTPHeaders?) -> URLRequest
    
    var baseURL: String { get }
    
}

extension BaseNetworkRouter {
    
    func personilisedRequest(method: Alamofire.HTTPMethod,
                             path: String,
                             params: Parameters? = nil,
                             encoding: ParameterEncoding = JSONEncoding.default,
                             headers: HTTPHeaders? = nil) -> URLRequest {
        
        
        
//        guard let token = SettingsStore.accessToken.value else {
//            fatalError("Can't send personilised request without user email. \(path), \(params)")
//        }
        
        return self.anonymousRequest(method: method,
                                     path: path,
                                     params: params,
                                     encoding: encoding,
                                     headers: headers)
    }
    
    func anonymousRequest(method: Alamofire.HTTPMethod,
                          path: String,
                          params: Parameters? = nil,
                          encoding: ParameterEncoding = JSONEncoding.default,
                          headers: HTTPHeaders? = nil)
        -> URLRequest {
            
            let url = URL(string: self.baseURL)!
            var request = URLRequest(url: url.appendingPathComponent(path))
            request.httpMethod = method.rawValue
            request.timeoutInterval = 30
            
            if let h = headers {
                for (key, value) in h {
                    request.setValue(value, forHTTPHeaderField: key)
                }
            }
            else {
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(URI.origin, forHTTPHeaderField: "Origin")
            }
            
            do {
                return try encoding.encode(request, with: params)
            }
            catch (let error) {
                fatalError("Error encoding request \(request), for params: \(String(describing: params)), details - \(error)")
            }
            
    }
    
    func anonymousRequest<T: Encodable>(method: Alamofire.HTTPMethod,
                                        path: String,
                                        encodableParam: T? = nil) -> URLRequest {
        
        var request = anonymousRequest(method: method, path: path)
        
        do {
            request.httpBody = try JSONEncoder().encode(encodableParam)
        }
        catch (let error) {
            fatalError("Error encoding request \(request), for params: \(String(describing: encodableParam)), details - \(error)")
        }
        
        return request
    }
                          
    
    var baseURL: String {
        return URI.restApiService + "/api/"
    }
 
}


struct URI {
    
    static var origin: String {
        
        let env = SettingsStore.environment.value
        
        guard env != "prod" else {
            return "https://rhythmic-rebellion.com"
        }
        
        let `protocol` = ["staging", "staging-dev"].contains(env) ? "https" : "http"
        
        return "\(`protocol`)://\(String(describing: env)).fan.rebellionretailsite.com"
    }
    
    static var restApiService: String {
        
        let env = SettingsStore.environment.value
        
        guard env != "prod" else {
            return "https://api.rhythmic-rebellion.com"
        }
        
        let `protocol` = ["staging", "staging-dev"].contains(env) ? "https" : "http"
        
        return "\(`protocol`)://\(String(describing: env)).api.rebellionretailsite.com"
        
    }
    
    static var webSocketService: String {
        
        let env = SettingsStore.environment.value
        
        guard env != "prod" else {
            return "wss://ws.rebellion-services.com"
        }
        
        if ["staging", "staging-dev"].contains(env) {
            return "wss://\(env).ws.rebellionretailsite.com:3000/"
        }
        
        return "ws://\(String(describing: env)).rebellionretailsite.com:3000/"
    }
    
}
