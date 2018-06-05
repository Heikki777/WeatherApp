//
//  FMIError.swift
//  WeatherApp
//
//  Created by Heikki Hämälistö on 01/06/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation

enum FMIError: Error{
    case InvalidURL(String)
    case UnsuccessfulResponse(String)
    case MissingValue(String)
}
