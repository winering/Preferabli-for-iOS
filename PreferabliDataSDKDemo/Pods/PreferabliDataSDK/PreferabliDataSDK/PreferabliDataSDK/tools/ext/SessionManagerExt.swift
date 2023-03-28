//
//  SyncExtension.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 12/13/17.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import Alamofire

extension SessionManager {
    
    internal func get(_ url: URLConvertible) -> DataResponse<Data> {
        return get(url, params: nil)
    }
    
    internal func get(_ url: URLConvertible, params: Parameters?) -> DataResponse<Data> {
        return syncRequest(url: url, parameters: params)
    }
    
    internal func delete(_ url: URLConvertible) -> DataResponse<Data> {
        return syncRequest(url: url, method: .delete)
    }
    
    internal func post(_ url: URLConvertible, params: Parameters?) throws -> DataResponse<Data> {
        return try syncRequest(urlString: url.asURL().absoluteString, method: "post", jsonObject: params)
    }
    
    internal func post(_ url: URLConvertible, json: Parameters?) throws -> DataResponse<Data> {
        return try syncRequest(urlString: url.asURL().absoluteString, method: "post", jsonObject: json)
    }
    
    internal func post(_ urlString: String, jsonObject: Any) throws -> DataResponse<Data> {
        return try syncRequest(urlString: urlString, method: "post", jsonObject: jsonObject)
    }
    
    internal func put(_ url: URLConvertible, json: Parameters?) throws -> DataResponse<Data> {
        return try syncRequest(urlString: url.asURL().absoluteString, method: "put", jsonObject: json)
    }
    
    internal func put(_ urlString: String, jsonObject: Any) throws -> DataResponse<Data> {
        return try syncRequest(urlString: urlString, method: "put", jsonObject: jsonObject)
    }
    
    internal func syncRequest(url: URLConvertible) -> DataResponse<Data> {
        return syncRequest(url: url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil)
    }
    
    internal func syncRequest(url: URLConvertible, parameters: Parameters?) -> DataResponse<Data> {
        return syncRequest(url: url, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: nil)
    }
    
    internal func syncRequest(url: URLConvertible, method: HTTPMethod) -> DataResponse<Data> {
        return syncRequest(url: url, method: method, parameters: nil, encoding: URLEncoding.default, headers: nil)
    }
    
    internal func syncRequest(url: URLConvertible, method: HTTPMethod, parameters: Parameters?) -> DataResponse<Data> {
        return syncRequest(url: url, method: method, parameters: parameters, encoding: URLEncoding.default, headers: nil)
    }
    
    internal func syncRequest(url: URLConvertible, method: HTTPMethod, parameters: Parameters?, encoding: ParameterEncoding, headers: HTTPHeaders?) -> DataResponse<Data> {
        if (Preferabli.loggingEnabled && parameters != nil) {
            print(parameters)
        }
        
        var outResponse: DataResponse<Data>!
        let semaphore = DispatchSemaphore(value: 0)
        
        self.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers).responseData { response in
            outResponse = response
            semaphore.signal()
        }
        semaphore.wait(timeout: DispatchTime.distantFuture)
        
        return outResponse
    }
    
    internal func syncRequest(urlString: String, method: String, jsonObject: Any) throws -> DataResponse<Data> {
        if (Preferabli.loggingEnabled) {
            print(jsonObject)
        }
        
        var outResponse: DataResponse<Data>!
        let semaphore = DispatchSemaphore(value: 0)
        
        let url = URL(string: urlString)
        var request = URLRequest(url: url!)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if (jsonObject is Data) {
            request.httpBody = jsonObject as! Data
        } else {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonObject)
        }
        
        self.request(request).responseData { response in
            outResponse = response
            semaphore.signal()
        }
        semaphore.wait(timeout: DispatchTime.distantFuture)
        
        return outResponse
    }

    internal func syncUpload(url: URLConvertible, data: Data) throws -> DataResponse<Data> {
        var outResponse: DataResponse<Data>!
        let semaphore = DispatchSemaphore(value: 0)
        
        let url = URL(string: try url.asURL().absoluteString)
        var request = URLRequest(url: url!)
        request.httpMethod = "post"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        self.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(data, withName: "file", fileName: "file.jpg", mimeType: "image/jpeg")
            if (PreferabliTools.isUserLoggedIn()) {
                multipartFormData.append(PreferabliTools.getUserId().stringValue.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: "user_id")
            }
        }, with: request) { result in
            switch result {
            case .success(let upload, _, _):
                upload.uploadProgress(closure: { progress in
                    if (Preferabli.loggingEnabled) {
                        print(progress)
                    }
                })
                
                upload.responseData { response in
                    outResponse = response
                    semaphore.signal()
                }
                
            case .failure(let encodingError):
                if (Preferabli.loggingEnabled) {
                    print(encodingError.localizedDescription)
                }
            }
        }
        semaphore.wait(timeout: DispatchTime.distantFuture)
        
        return outResponse
    }
    
    internal func syncUpload(url: URLConvertible, data: Data, position: String) throws -> DataResponse<Data> {
        var outResponse: DataResponse<Data>!
        let semaphore = DispatchSemaphore(value: 0)
        
        let url = URL(string: try url.asURL().absoluteString)
        var request = URLRequest(url: url!)
        request.httpMethod = "post"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        self.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(data, withName: "file", fileName: "file.jpg", mimeType: "image/jpeg")
            multipartFormData.append(position.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: "position")
        }, with: request) { result in
            switch result {
            case .success(let upload, _, _):
                upload.uploadProgress(closure: { progress in
                    if (Preferabli.loggingEnabled) {
                        print(progress)
                    }
                })
                
                upload.responseData { response in
                    outResponse = response
                    semaphore.signal()
                }
                
            case .failure(let encodingError):
                if (Preferabli.loggingEnabled) {
                    print(encodingError.localizedDescription)
                }
            }
        }
        semaphore.wait(timeout: DispatchTime.distantFuture)
        
        return outResponse
    }
}
