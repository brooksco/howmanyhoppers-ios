//
//  ViewController.swift
//  How Many Hoppers
//
//  Created by Colin Brooks on 2/8/18.
//  Copyright © 2018 Whitney Museum of American Art. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    // MARK: Properties
    @IBOutlet var hopperCountLabel: UILabel!
    
    var hopperCount: Int = 0
    var hopperData: NSManagedObject?
    let defaultSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "HopperData")
        
        do {
            hopperData = try managedContext.fetch(fetchRequest).first
            
            if (hopperData != nil) {
                self.hopperCountLabel.text = String(hopperData!.value(forKeyPath: "count") as! Int)
            }
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        update()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.update), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    @objc func update() {
        // Only update if the count is more than an hour old
        let timeAgo = Calendar.current.date(byAdding: .hour, value: -1, to: Date())
        
        let lastUpdated = hopperData?.value(forKeyPath: "lastUpdated") as? Date
        if (lastUpdated != nil) {
            if lastUpdated! < timeAgo! {
                    print("UPDATING BECAUSE TIME")
                    hopperCount = 0
                    collectionCall(url: "http://collection.whitney.org/json/groups/5/?page=1&format=json")
            }
            
        } else {
            print("UPDATING NEW")
            hopperCount = 0
            collectionCall(url: "http://collection.whitney.org/json/groups/5/?page=1&format=json")
        }
    }
    
    func collectionCall(url: String) {
        dataTask?.cancel()
        dataTask = defaultSession.dataTask(with: URL(string: url)!) { data, response, error in
            defer { self.dataTask = nil }
            
            if let error = error {
                print("DataTask error: " + error.localizedDescription)
                
            } else if let data = data,
                let response = response as? HTTPURLResponse,
                response.statusCode == 200 {
                
                DispatchQueue.main.async {
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any] {
                        
                        if let groupObjects = json["group_objects"] as? [String: Any] {
                            
                            if let objects = groupObjects["results"] as? [[String: Any]] {
                                
                                for object in objects {
                                    
                                    if (object["artist_name"] as! String == "Edward Hopper") {
                                        self.hopperCount += 1;
                                    }
                                }
                            }
                            
                            let next = groupObjects["next"] as? String
                            if next != nil {
                                self.collectionCall(url: next!);
                                
                            } else {
                                print("DONE")
                                self.hopperCountLabel.text = String(self.hopperCount)
                                
                                self.save(count: self.hopperCount)
                            }
                            
                        }
                    }
                }
            }
        }
        
        dataTask?.resume()
    }
    
    func save(count: Int) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }

        let managedContext = appDelegate.persistentContainer.viewContext
        
        // See if it exists already
        if (hopperData != nil) {
            hopperData!.setValue(count, forKeyPath: "count")
            hopperData!.setValue(NSDate(), forKeyPath: "lastUpdated")
            print("SAVING EXISTING")
            
        } else {
            let entity = NSEntityDescription.entity(forEntityName: "HopperData", in: managedContext)!
            let newHopperData = NSManagedObject(entity: entity, insertInto: managedContext)
            
            newHopperData.setValue(count, forKeyPath: "count")
            newHopperData.setValue(NSDate(), forKeyPath: "lastUpdated")
            hopperData = newHopperData
            print("SAVING NEW")
        }
        
        do {
            try managedContext.save()
            
        } catch {
            print("COULD NOT SAVE")
        }
    }
}

