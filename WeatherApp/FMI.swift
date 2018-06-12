//
//  FMI.swift
//  WeatherApp
//
//  Created by Heikki Hämälistö on 01/06/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation
import SWXMLHash
import PromiseKit
import Alamofire

struct FMI{
    
    static let apiKey = FMI_API_KEY
    
    func loadWeather(forPlace place: String, parameters: [String]) -> Promise<XMLIndexer>{
        return Promise { result in
            let urlString = "https://data.fmi.fi/fmi-apikey/\(FMI.apiKey)/wfs?request=getFeature&storedquery_id=fmi::forecast::hirlam::surface::point::timevaluepair&parameters=\(parameters.joined(separator: ","))&place=\(place)"
            
            guard let url = URL(string: urlString) else{
                result.reject(FMIError.InvalidURL(urlString))
                return
            }
            
            DispatchQueue.global(qos: .background).async {
                Alamofire.request(url, method: .get, parameters: nil)
                .validate()
                .responseString(completionHandler: { (response) in
                    guard response.result.isSuccess else {
                        result.reject(FMIError.UnsuccessfulResponse("Error! Weather data couldn't be loaded"))
                        return
                    }
                    
                    guard let xmlString = response.result.value else{
                        result.reject(FMIError.MissingValue("Error! The response is missing value"))
                        return
                    }
                    
                    // Parse the xml string
                    let xml = SWXMLHash.parse(xmlString)
                    result.fulfill(xml)
                })
            }
        }
    }

}

enum WeatherFeature: String{
    case temperature = "mts-1-1-temperature"
    case weatherSymbol3 = "mts-1-1-WeatherSymbol3"
    case windSpeedMs = "mts-1-1-windspeedms"
}


