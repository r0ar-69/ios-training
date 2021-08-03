//
//  WeatherModel.swift
//  Example
//
//  Created by 渡部 陽太 on 2020/04/01.
//  Copyright © 2020 YUMEMI Inc. All rights reserved.
//

import Foundation
import YumemiWeather

class WeatherModelImpl: WeatherModel {
    
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return dateFormatter
    }()
    
    func jsonString(from request: Request) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        
        guard let requestData = try? encoder.encode(request),
              let requestJsonString = String(data: requestData, encoding: .utf8) else {
            throw WeatherError.jsonEncodeError
        }
        
        return requestJsonString
    }
    
    func response(from jsonString: String) throws -> Response {
        guard let responseData = jsonString.data(using: .utf8) else {
            throw WeatherError.jsonDecodeError
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        guard let response = try? decoder.decode(Response.self, from: responseData) else {
            throw WeatherError.jsonDecodeError
        }
        
        return response
    }
    
    func fetchWeather(at area: String, date: Date, completion: @escaping (Result<Response, WeatherError>) -> Void) {
        DispatchQueue.global().async { [weak self] in
            do {
                if let self = self {
                    let request = Request(area: area, date: date)
                    let requestJson = try self.jsonString(from: request)
                    let responseJson = try YumemiWeather.syncFetchWeather(requestJson)
                    let response = try self.response(from: responseJson)
                    
                    completion(.success(response))
                } else {
                    completion(.failure(.unknownError))
                }
            } catch let error as YumemiWeatherError {
                completion(.failure(WeatherError(error: error)))
            } catch {
                completion(.failure(error as! WeatherError))
                print("err:\(error)")
            }
        }
    }
}

extension WeatherError {
    init(error: YumemiWeatherError) {
        switch error {
        case .unknownError:
            self = .unknownError
        case .invalidParameterError:
            self = .invalidParameterError
        }
    }
}
