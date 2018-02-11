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
        
        collectionCall(url: "http://collection.whitney.org/json/groups/5/?page=1&format=json")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //1
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        //2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "HopperData")
        
        //3
        do {
            hopperData = try managedContext.fetch(fetchRequest).first
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        print("HOPPER DATA")
        print(hopperData)
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
//                                            self.hopperData.value(forKeyPath: "count") as? Int
//                                            self.hopperCountLabel.text = String(self.hopperCount)
                                        }
                                    }
                                }
                                
                                let next = groupObjects["next"] as? String
                                if next != nil {
//                                    self.hopperCountLabel.text = String(self.hopperCount)
                                    self.collectionCall(url: next!);
                                    print("NEXT")
                                    
                                } else {
                                    print("DONE")
                                    self.hopperCountLabel.text = String(self.hopperCount)
                                    
                                    // TODO: Save count to core data object
                                }
                                
                            }
                        }
                    }
                }
            }
        
            dataTask?.resume()
    }
    
//    func save(name: String) {
//
//        guard let appDelegate =
//            UIApplication.shared.delegate as? AppDelegate else {
//                return
//        }
//
//        // 1
//        let managedContext =
//            appDelegate.persistentContainer.viewContext
//
//        // 2
//        let entity =
//            NSEntityDescription.entity(forEntityName: "HopperData",
//                                       in: managedContext)!
//
//        let person = NSManagedObject(entity: entity,
//                                     insertInto: managedContext)
//
//        // 3
//        person.setValue(name, forKeyPath: "name")
//
//        // 4
//        do {
//            try managedContext.save()
//            people.append(person)
//        } catch let error as NSError {
//            print("Could not save. \(error), \(error.userInfo)")
//        }
//    }
}

