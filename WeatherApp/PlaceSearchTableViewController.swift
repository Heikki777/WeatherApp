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
        
        self.searchResults.removeAll()
        guard let searchBarText = searchController.searchBar.text else{
            return
        }
        
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchBarText
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            
            guard let response = response else{
                return
            }
            let names = response.mapItems.compactMap{ $0.placemark.locality }
            for name in names{
                if !self.searchResults.contains(name){
                    self.searchResults.append(name)
                }
            }
            self.tableView.reloadData()
        }
    }
}
