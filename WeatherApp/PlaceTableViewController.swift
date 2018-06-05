//
//  PlaceTableViewController.swift
//  WeatherApp
//
//  Created by Heikki Hämälistö on 04/06/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import CoreData

class PlaceTableViewController: UITableViewController {
    
    // Dismiss the ViewController
    @IBAction func close() {
        appDelegate.saveContext()
        performSegue(withIdentifier: Segue.unwindSegueToPageVC.rawValue, sender: self)
    }
    
    fileprivate let reuseIdentifier = "placeCell"
    
    lazy var appDelegate: AppDelegate = {
        return (UIApplication.shared.delegate as! AppDelegate)
    }()
    
    lazy var context: NSManagedObjectContext = {
        return appDelegate.persistentContainer.viewContext
    }()
    
    lazy var fetchedResultsController: NSFetchedResultsController<Place> = {
        return PlaceFetchedResultsController(managedObjectContext: self.context, tableView: self.tableView)
    }()
    
    var selectionDelegate: TableViewSelectionDelegate?
    var currentLocation: String?{
        return appDelegate.currentLocation
    }
    
    var roundButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func object(at indexPath: IndexPath) -> Place{
        return fetchedResultsController.object(at: indexPath)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = fetchedResultsController.sections?[section] else{
            return 0
        }
        return section.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        let place = object(at: indexPath)
        
        // Configure the cell...
        cell.textLabel?.text = place.name
        cell.textLabel?.textColor = .white

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !tableView.isEditing{
            let selectedPlace = object(at: indexPath)
            if let placeName = selectedPlace.name{
                selectionDelegate?.didSelect(item: placeName)
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        switch editingStyle{
        case .delete:
            let managedObject = object(at: indexPath)
            context.delete(managedObject)
            appDelegate.saveContext()
        default:
            break
        }
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // The first row (current location) can not be edited.
        return true
    }
    
    // Return true if a name with place already exists in Core Data.
    // Otherwise return false
    func placeEntityExists(name: String) -> Bool {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Place")
        fetchRequest.predicate = NSPredicate(format: "%K == %@", "name", name)
        
        var results: [NSManagedObject] = []
        
        do {
            results = try context.fetch(fetchRequest)
        }
        catch {
            print("error executing fetch request: \(error)")
        }
        
        let exists = results.count > 0
        return exists
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segue.showSearchSegue.rawValue{
            guard let placeSearchTableVC = segue.destination as? PlaceSearchTableViewController else{
                print("Error! Segue destination is not PlaceSearchTableViewController")
                return
            }
            placeSearchTableVC.selectionDelegate = self
            placeSearchTableVC.modalPresentationStyle = .overCurrentContext
        }
    }
    
}

// MARK: - TableViewSelectionDelegate
extension PlaceTableViewController: TableViewSelectionDelegate{
    func didSelect(item: Any){
        if let nameOfPlace = item as? String{
            if !placeEntityExists(name: nameOfPlace){
                let entity = NSEntityDescription.entity(forEntityName: "Place", in: context)
                let newPlace = NSManagedObject(entity: entity!, insertInto: context)
                newPlace.setValue(nameOfPlace, forKey: "name")
                appDelegate.saveContext()
            }
        }
    
    }
}
