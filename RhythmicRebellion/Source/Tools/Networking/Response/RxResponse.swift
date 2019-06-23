//
//  RxResponse.swift
//
//
//  Created by Vlad Soroka on 7/22/17.
//  Copyright © 2017   All rights reserved.
//

import Foundation
import Alamofire
import RxSwift

extension Reactive where Base : BaseNetworkRouter {
    
    func rawJSONResponse() -> Maybe<Any> {
        return base.rxJSONResponse()
    }
    
    func emptyResponse() -> Maybe<Void> {
        return base.rxResponse()
            .map { _ in }
    }
    
    func response<T: Decodable>(type: T.Type) -> Maybe<T> {
        return base.rxResponse()
            .map { (input) -> T in
                
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                return try decoder.decode(T.self, from: input)
            }
    }
    
    func baseResponse<T: Decodable>(type: T.Type) -> Maybe<T> {
        return response(type: BaseReponse<T>.self)
            .map { $0.data }
    }
}

extension URLRequestConvertible {
    
    fileprivate func rxResponse() -> Maybe<Data> {
        
        return Observable.create { (subscriber) -> Disposable in
            
            let request = DataLayer.get.network.sessionManager.request(self)
            
            request
                .validate()
                .responseData { (response: DataResponse< Data >) in
                    
                if let e = response.result.error {
                    
                    if let maybeData = response.data {
                        
                        if let restApiResponse = try? JSONDecoder().decode(ErrorResponse.self,
                                                                           from: maybeData) {
                            subscriber.onError( RRError.server(error: restApiResponse) )
                            return
                        }
                    }
                    
                    subscriber.onError(e)
                    return
                }
                    
                guard let mappedResponse = response.result.value else {
                    fatalError("Result is not success and not error")
                }
                
                subscriber.onNext( mappedResponse )
                subscriber.onCompleted()
            }
            
            return Disposables.create { request.cancel() }
        }
        .asMaybe()   
    }
    
    fileprivate func rxJSONResponse() -> Maybe<Any> {
        
        return rxResponse().map { (data) -> Any in
            
            var json: Any! = nil
            do {
                json = try JSONSerialization.jsonObject(with: data, options: [])
            } catch (let e) {
                throw AFError.responseSerializationFailed(reason: .jsonSerializationFailed(error: e))
            }
            
            return json
        }

    }
}

