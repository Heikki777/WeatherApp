//
//  PageViewController.swift
//  WeatherApp
//
//  Created by Heikki Hämälistö on 03/06/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import CoreData

class PageViewController: UIPageViewController {
    
    lazy var appDelegate: AppDelegate = {
        return (UIApplication.shared.delegate as! AppDelegate)
    }()
    
    lazy var context: NSManagedObjectContext = {
        return appDelegate.persistentContainer.viewContext
    }()
    
    var pages: [ViewController] = []
    
    func createPages() -> [ViewController]{
        var result: [ViewController] = []
        
        // First ViewController is the one with GPS location
        result.append(weatherViewController(withPlace: nil))
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Place")
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            if let places = try context.fetch(fetchRequest) as? [Place]{
                for place in places{
                    if let placeName = place.name{
                        result.append(weatherViewController(withPlace: placeName))
                    }
                }
            }
            return result
        }
        catch {
            print("Error! Creating pages failed")
            return result
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        self.delegate = self
        
        self.pages = createPages()
        
        self.view.backgroundColor = appDelegate.bgColor
        
        if let firstVC = pages.first{
            setViewControllers([firstVC], direction: .forward, animated: true, completion: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    fileprivate func weatherViewController(withPlace place: String?) -> ViewController{
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ViewController") as! ViewController
        vc.locality = place
        vc.useGPSLocation = place == nil
        return vc
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segue.showPlaceListSegue.rawValue{
            if let placeTableViewController = segue.destination as? PlaceTableViewController{
                placeTableViewController.selectionDelegate = self
            }
        }
    }
    
    @IBAction func unwindToPageVC(segue: UIStoryboardSegue){
        self.pages = createPages()
        if let firstVC = pages.first{
            setViewControllers([firstVC], direction: .forward, animated: true, completion: nil)
        }
    }
}

extension PageViewController: UIPageViewControllerDataSource{
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    
        if pages.count == 1{
            return nil
        }
        
        guard let index = pages.index(of: viewController as! ViewController) else {
            return nil
        }
        
        if index == 0{
            return nil
        }
        
        let prevIndex = index - 1

        return pages[prevIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        if pages.count == 1{
            return nil
        }
        
        guard let index = pages.index(of: viewController as! ViewController) else {
            return nil
        }
        
        let nextIndex = index + 1
        
        guard nextIndex < pages.count else {
            return nil
        }
        
        return pages[nextIndex]
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return pages.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        
        if let first = pageViewController.viewControllers?.first as? ViewController{
            if let index = pages.index(of: first){
                return index
            }
        }
        return 0
    }
}

extension PageViewController: UIPageViewControllerDelegate{

}

// MARK: - TableViewSelectionDelegate
extension PageViewController: TableViewSelectionDelegate{
    func didSelect(item: Any) {
        
        self.pages = createPages()
        
        if let name = item as? String{
            if let firstVC = (self.pages.filter{$0.locality == name}).first{
                var direction = UIPageViewControllerNavigationDirection.forward
                if let index = self.pages.index(of: firstVC){
                    if index < pages.count{
                        direction = UIPageViewControllerNavigationDirection.reverse
                    }
                }
                setViewControllers([firstVC], direction: direction, animated: true, completion: nil)
            }
        }
    }
}

