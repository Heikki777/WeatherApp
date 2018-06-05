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
    
    static let apiKey = YOUR_FMI_API_KEY
    
    func loadWeather(forPlace place: String, parameters: [String]) -> Promise<XMLIndexer>{
        return Promise { result in
            let urlString = "https://data.fmi.fi/fmi-apikey/\(FMI.apiKey)/wfs?request=getFeature&storedquery_id=fmi::forecast::hirlam::surface::point::timevaluepair&parameters=\(parameters.joined(separator: ","))&place=\(place)"
            
            guard let url = URL(string: urlString) else{
                result.reject(FMIError.InvalidURL(urlString))
                return
            }
            
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

enum WeatherFeature: String{
    case temperature = "mts-1-1-temperature"
    case weatherSymbol3 = "mts-1-1-WeatherSymbol3"
    case windSpeedMs = "mts-1-1-windspeedms"
}

enum WeatherSymbol: Int{
    case selkeaa = 1
    case puolipilvista = 2
    case heikkoja_sadekuuroja = 21
    case sadekuuroja = 22
    case voimakkaita_sadekuuroja = 23
    case pilvista = 3
    case heikkoa_vesisadetta = 31
    case vesisadetta = 32
    case voimakasta_vesisadetta = 33
    case heikkoja_lumikuuroja = 41
    case lumikuuroja = 42
    case voimakkaita_lumikuuroja = 43
    case heikkoa_lumisadetta = 51
    case lumisadetta = 52
    case voimakasta_lumisadetta = 53
    case ukkoskuuroja = 61
    case voimakkaita_ukkoskuuroja = 62
    case ukkosta = 63
    case voimakasta_ukkosta = 64
    case heikkoja_rantakuuroja = 71
    case rantakuuroja = 72
    case voimakkaita_rantakuuroja = 73
    case heikkoa_rantasadetta = 81
    case rantasadetta = 82
    case voimakasta_rantasadetta = 83
    case utua = 91
    case sumua = 92
    
    var description: String{
        switch self{
        case .selkeaa: return "selkeää"
        case .puolipilvista: return "puolipilvistä"
        case .heikkoja_sadekuuroja: return "heikkoja sadekuuroja"
        case .sadekuuroja: return "sadekuuroja"
        case .voimakkaita_sadekuuroja: return "voimakkaita sadekuuroja"
        case .pilvista: return "pilvistä"
        case .heikkoa_vesisadetta: return "heikkoa vesisadetta"
        case .vesisadetta: return "vesisadetta"
        case .voimakasta_vesisadetta: return "voimakasta vesisadetta"
        case .heikkoja_lumikuuroja: return "heikkoja lumikuuroja"
        case .lumikuuroja: return "lumikuuroja"
        case .voimakkaita_lumikuuroja: return "voimakkaita lumikuuroja"
        case .heikkoa_lumisadetta: return "heikkoa lumisadetta"
        case .lumisadetta: return "lumisadetta"
        case .voimakasta_lumisadetta: return "voimakasta lumisadetta"
        case .ukkoskuuroja: return "ukkoskuuroja"
        case .voimakkaita_ukkoskuuroja: return "voimakkaita ukkoskuuroja"
        case .ukkosta: return "ukkosta"
        case .voimakasta_ukkosta: return "voimakasta ukkosta"
        case .heikkoja_rantakuuroja: return "heikkoja räntäkuuroja"
        case .rantakuuroja: return "räntäkuuroja"
        case .voimakkaita_rantakuuroja: return "voimakkaita räntäkuuroja"
        case .heikkoa_rantasadetta: return "heikkoa räntäsadetta"
        case .rantasadetta: return "räntäsadetta"
        case .voimakasta_rantasadetta: return "voimakasta räntäsadetta"
        case .utua: return "utua"
        case .sumua: return "sumua"
        }
    }
    
    var image: UIImage?{
        return UIImage(named: "\(self.rawValue)")
    }

}
