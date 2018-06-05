//
//  WeatherPoint.swift
//  WeatherApp
//
//  Created by Heikki Hämälistö on 02/06/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation

struct WeatherPoint{
    var date: Date
    var temperature: Int?
    var symbol: WeatherSymbol?
    var windSpeedMs: Double?
    
    init(date: Date){
        self.date = date
    }
}
