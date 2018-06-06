//
//  ViewController.swift
//  WeatherApp
//
//  Created by Heikki Hämälistö on 31/05/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import CoreLocation
import SWXMLHash

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var currentWeatherIconImageView: UIImageView!
    @IBOutlet weak var currentWeatherDescriptionLabel: UILabel!
    @IBOutlet weak var currentTemperatureLabel: UILabel!
    @IBOutlet weak var weatherTableView: UITableView!
    @IBOutlet weak var compassImageView: UIImageView!
    
    let reuseIdentifier = "weatherCell"
    let locationManager: CLLocationManager = CLLocationManager()
    let unknownLocationText: String = "Tuntematon sijainti"
    let fmiApi = FMI()
    let sectionHeaderHeight: CGFloat = 25
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return formatter
    }()
    
    lazy var geocoder: CLGeocoder = {
        return CLGeocoder.init()
    }()
    
    // Refresh control to refresh the tableView when pull-to-refresh
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(ViewController.refresh(_:)), for: UIControlEvents.valueChanged)
        refreshControl.tintColor = UIColor.white
        return refreshControl
    }()
    
    var useGPSLocation: Bool = true
    var sections: [String] = []
    var tableDataModel = Dictionary<String, [WeatherPoint]>()
    var weatherPoints = [WeatherPoint]()
    var currentWeatherPoint: WeatherPoint?{
        didSet{
            guard let currentWeatherPoint = currentWeatherPoint else{
                return
            }
            
            if let temperature = currentWeatherPoint.temperature{
                currentTemperatureLabel.text = "\(temperature) °C"
            }
            
            if let symbol = currentWeatherPoint.symbol{
                currentWeatherIconImageView.image = symbol.image
                currentWeatherDescriptionLabel.text = symbol.description
            }
        }
    }
    
    var locality: String?
    
    func reset(){
        currentTemperatureLabel.text = ""
        currentWeatherIconImageView.image = nil
        weatherPoints.removeAll()
        weatherTableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    @objc func refresh(_ refreshControl: UIRefreshControl){
        self.loadWeather()
    }
    
    func loadWeather(){
        self.reset()
        
        guard let locality = locality else{
            print("Error! Could not load the weather. Locality is nil")
            return
        }
        
        fmiApi.loadWeather(forPlace: locality, parameters: ["temperature", "WeatherSymbol3", "windspeedms"])
        .done { xml in
            self.parseWeatherXML(xml)
            self.findCurrentWeatherPoint()
            self.createTableDataModel()
        }
        .catch { error in
            print(error.localizedDescription)
            self.showAlert(title: "Virhe", message: "Säädataa ei löydetty sijainnille: \(locality)")
        }
        .finally {
            self.weatherTableView.reloadData()
            
            // Show compass icon only for the GPS location
            if self.useGPSLocation{
                self.compassImageView.isHidden =  false
                self.executeAnimations()
            }
        }
    }
    
    func executeAnimations(){
        
        DispatchQueue.main.async {
            self.rotate360degrees(view: self.compassImageView)
        }
        
    }
    
    func rotate360degrees(view: UIView, duration: Double = 2.0){
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: duration/2, delay: 0, options: UIViewAnimationOptions.curveLinear, animations: { () -> Void in
                view.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            }, completion: nil)
            UIView.animate(withDuration: duration/2, delay: 0, options: UIViewAnimationOptions.curveLinear, animations: { () -> Void in
               view.transform = CGAffineTransform(rotationAngle: CGFloat.pi * 2.0)
            }, completion: nil)
        }
    }
    
    // Creates table sections (dates)
    func createTableDataModel(){
        sections.removeAll()
        tableDataModel.removeAll()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.init(identifier: "fi")
        dateFormatter.dateFormat = "EE d. MMMM yyyy"
        for point in weatherPoints{
            let date = point.date
            let section = dateFormatter.string(from: date)
            if !sections.contains(section){
                sections.append(section)
                tableDataModel[section] = []
            }
            tableDataModel[section]?.append(point)
        }
    }
    
    func findCurrentWeatherPoint(){
        let now = Date.init()
        for point in weatherPoints{
            // Remove the passed points
            if point.date < now{
                weatherPoints.removeFirst()
            }
            // Set the current point
            else if point.date >= now{
                currentWeatherPoint = point
                break
            }
        }
    }
    
    func parseWeatherXML(_ xml: XMLIndexer){
        let root = xml["wfs:FeatureCollection"]
        let features = root.children
        
        for feature in features {
            let ptso = feature["omso:PointTimeSeriesObservation"]
            let measurementTimeSeries = ptso["om:result"]["wml2:MeasurementTimeseries"]
            
            guard
                let gmlID: String = try? measurementTimeSeries.value(ofAttribute: "gml:id"),
                let weatherFeature = WeatherFeature(rawValue: gmlID)
            else {
                continue
            }
        
            for (index, point) in measurementTimeSeries.children.enumerated(){
                if let dateString = point["wml2:MeasurementTVP"]["wml2:time"].element?.text{
                    if weatherPoints.count < index+1{
                        if let date = dateFormatter.date(from: dateString){
                            weatherPoints.append(WeatherPoint(date: date))
                        }
                    }
                    if let valueString = point["wml2:MeasurementTVP"]["wml2:value"].element?.text{
                        switch weatherFeature{
                        case .temperature:
                            if let temperatureDouble = Double(valueString)?.rounded(){
                                let roundedTemperature = Int.init(temperatureDouble)
                                weatherPoints[index].temperature = roundedTemperature
                            }
                        case .windSpeedMs:
                            if let windSpeedMs = Double(valueString){
                                weatherPoints[index].windSpeedMs = windSpeedMs
                            }
                        case .weatherSymbol3:
                            if let symbolDouble = Double(valueString)?.rounded(){
                                let symbolInteger = Int.init(symbolDouble)
                                let symbol = WeatherSymbol.init(rawValue: symbolInteger)
                                weatherPoints[index].symbol = symbol
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.compassImageView.isHidden = true
        self.weatherTableView.delegate = self
        self.weatherTableView.dataSource = self
        self.weatherTableView.addSubview(refreshControl)
        
        if useGPSLocation{
            locationManager.delegate = self
            
            // The app does not need to know the user's coordinates exactly. 1km accuracy is enough.
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            
            // Requests permission to use location services while the app is in the foreground.
            locationManager.requestWhenInUseAuthorization()
            
            // Request location
            locationManager.requestLocation()
            
            // Monitor significant location changes
            locationManager.startMonitoringSignificantLocationChanges()
            
            // Start updating location
            locationManager.startUpdatingLocation()
        }
        else{
            self.locationLabel.text = locality
            self.loadWeather()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else{
            print("No location")
            showAlert(title: "Virhe", message: "Sijaintia ei löytynyt")
            compassImageView.isHidden = true
            return
        }

        // Reverse-geocoding ( lat, long coordinates -> user-readable address )
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let error = error {
                print(error.localizedDescription)
                self.locality = nil
                return
            }
            
            guard let placemark = placemarks?.first else{
                print("Error! Place not found!")
                self.locality = nil
                return
            }
            
            self.locality = placemark.locality
            
            guard let locality = self.locality else{
                self.locationLabel.text = self.unknownLocationText
                self.showAlert(title: "Virhe", message: "Sijaintia ei löytynyt")
                return
            }
            
            // Load the weather data if the user's location was found.
            self.locationLabel.text = locality
            self.loadWeather()

        }
        
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
    // Shows alert with and "OK" button and the given title and the message
    func showAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate{

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: sectionHeaderHeight))
        let label = UILabel(frame: CGRect(x: 15, y: 0, width: tableView.bounds.width - 30, height: sectionHeaderHeight))
        view.backgroundColor = UIColor.init(red: 75/255.0, green: 58/255.0, blue: 248/255.0, alpha: 1.0)
        label.font = UIFont.init(name: "HelveticaNeue", size: 15)
        label.textColor = UIColor.white
        label.text = sections[section]
        view.addSubview(label)
        
        return view
    }

}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionName = sections[section]
        if let rows = tableDataModel[sectionName]{
            return rows.count
        }
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! WeatherTableViewCell
        
        if let weatherPoint = tableDataModel[section]?[indexPath.row]{
            cell.configure(with: weatherPoint)
        }
        
        return cell
    }
}
