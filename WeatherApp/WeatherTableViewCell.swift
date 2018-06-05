//
//  WeatherTableViewCell.swift
//  WeatherApp
//
//  Created by Heikki Hämälistö on 02/06/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit

class WeatherTableViewCell: UITableViewCell {

    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var windSpeedLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configure(with weatherPoint: WeatherPoint){
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        timeLabel.text = dateFormatter.string(from: weatherPoint.date)
        
        if let temperature = weatherPoint.temperature{
            temperatureLabel.text = "\(temperature) °C"
        }
        
        if let windSpeed = weatherPoint.windSpeedMs{
            windSpeedLabel.text = "Tuuli: \(windSpeed) m/s"
        }
        
        iconImageView.image = nil
        if let symbol = weatherPoint.symbol{
            iconImageView.image = symbol.image
            descriptionLabel.text = symbol.description
        }
    }
    
}
