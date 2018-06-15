//
//  PlaceSearchTableViewController.swift
//  WeatherApp
//
//  Created by Heikki Hämälistö on 04/06/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import MapKit

class PlaceSearchTableViewController: UITableViewController{
    
    private let reuseIdentifier = "searchResultCell"
    let searchController = UISearchController(searchResultsController: nil)
    var searchResults: [String] = [String]()
    var mapView: MKMapView = MKMapView()
    var selectionDelegate: TableViewSelectionDelegate?
    
    lazy var searchDelayTimer: Timer = {
       return Timer()
    }()

    lazy var appDelegate: AppDelegate = {
        return (UIApplication.shared.delegate as! AppDelegate)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Places"
        searchController.searchBar.delegate = self
        searchController.searchBar.showsCancelButton = true
        searchController.searchBar.backgroundColor = appDelegate.bgColor
        searchController.searchBar.barTintColor = appDelegate.bgColor
        
        let cancelButtonAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes , for: .normal)
        
        navigationItem.searchController = searchController
        self.tableView.tableHeaderView = self.searchController.searchBar
        definesPresentationContext = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)

        let searchResult = searchResults[indexPath.row]
        
        // Configure the cell...
        cell.textLabel?.text = searchResult
        cell.textLabel?.textColor = UIColor.white

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let place = searchResults[indexPath.row]
        self.searchController.searchBar.endEditing(true)
        self.searchController.isActive = false
        self.dismiss(animated: true) {
            self.selectionDelegate?.didSelect(item: place)
        }
    }

}

extension PlaceSearchTableViewController: UISearchBarDelegate{
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchController.searchBar.endEditing(true)
        self.searchController.isActive = false
        self.dismiss(animated: true, completion: nil)
    }
}

extension PlaceSearchTableViewController: UISearchResultsUpdating{
    func updateSearchResults(for searchController: UISearchController) {
        
        guard let searchBarText = searchController.searchBar.text else{
            
            return
        }
        guard searchBarText.count > 2 else{
            self.searchDelayTimer.invalidate()
            return
        }
        
        self.searchDelayTimer.invalidate()
        self.searchDelayTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { (timer) in
            
            self.searchResults.removeAll()
            self.tableView.reloadData()
            
            let request = MKLocalSearchRequest()
            request.naturalLanguageQuery = searchBarText
            request.region = self.mapView.region
            
            let search = MKLocalSearch(request: request)
            search.start { (response, error) in
                
                self.searchResults.removeAll()
                self.tableView.reloadData()
                
                if let error = error{
                    print(error.localizedDescription)
                    return
                }
                
                guard let response = response else{
                    print("No response")
                    return
                }
                
                let names = response.mapItems.compactMap{ $0.placemark.locality }
                for name in names{
                    if !self.searchResults.contains(name) && name.lowercased().contains(searchBarText.lowercased()){
                        self.searchResults.append(name)
                    }
                }
                self.tableView.reloadData()
            }
        })
    }
}
