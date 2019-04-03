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
                request.setValue(Application.URI.origin, forHTTPHeaderField: "Origin")
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
        return Application.URI.restApiService + "/api/"
    }
 
}

