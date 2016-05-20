/*
 Charlie Mathews, 2016
 This work is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License
 */


import Foundation
import CoreData
import UIKit

class VenueRepository : NSObject, NSURLSessionDelegate, NSURLSessionDownloadDelegate {
    
    dynamic var foundResults : Bool = false
    dynamic var queryInProgress : Bool = false
    var results : [Venue] = []
    var task : NSURLSessionDownloadTask? = nil
    
    var latitude : Double = 0.00
    var longitude : Double = 0.00
    var total : Int = 0
    
    static let sharedInstance : VenueRepository = VenueRepository()
    
    private override init() {
        super.init()
    }
    
    func hasMoved(newLat : Double, newLng : Double) -> Bool {
        let defaults : NSUserDefaults = NSUserDefaults()
        let oldLat = defaults.doubleForKey("lat")
        let oldLng = defaults.doubleForKey("lng")
        
        if (calcuateDistance(newLat, lng1: newLng, lat2: oldLat, lng2: oldLng)*MIinKM) > 1 {
            return true
        }
        return false
    }
    
    func deleteStoredData() {
        let moc = getMOC()
        let fetchRequest = NSFetchRequest(entityName: "Venue")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            print("Deleting old results from core data.")
            try moc.executeRequest(deleteRequest)
            try moc.save()
        } catch let error as NSError {
            print("Delete failed: \(error), \(error.userInfo)")
        }
    }
    
    func fetchData(newLat: Double, newLng : Double) -> Bool {
        
        if hasMoved(newLat, newLng: newLng) {
            
            print("You have moved >1km. Pulling fresh results.")
            
            get(newLat, lng: newLng)
            let defaults : NSUserDefaults = NSUserDefaults()
            defaults.setDouble(newLat, forKey: "lat")
            defaults.setDouble(newLng, forKey: "lng")
            
        } else {
            
            print("You have not moved. Pulling from core data.")
            
            clear()
            
            latitude = newLat
            longitude = newLng
            
            let fetchRequest = NSFetchRequest(entityName: "Venue")
            do {
                let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
                let managedContext = appDelegate!.managedObjectContext
                let results = try managedContext.executeFetchRequest(fetchRequest) as! [NSManagedObject]
                print("There are \(results.count) venues in core data.")
                for r in results {
                    let venue = Venue()
                    venue.id = r.valueForKey("id") as! String
                    venue.name = r.valueForKey("name") as! String
                    venue.category = r.valueForKey("category") as! String
                    venue.lat = r.valueForKey("lat") as! Double
                    venue.lng = r.valueForKey("lng") as! Double
                    venue.icon_url = r.valueForKey("icon_url") as! String
                    venue.thumb_url = r.valueForKey("thumb_url") as! String
                    venues.results.append(venue)
                }
                if results.count > 0 {
                    foundResults = true
                }
            } catch let error as NSError {
                print("Could not fetch \(error), \(error.userInfo)")
            }
        }
        
        return false
    }
    
    func get(lat : Double, lng : Double) {
        
        deleteStoredData()
        
        if queryInProgress == true {
            queryInProgress = false
            task!.cancel()
            clear()
        }
        
        foundResults = false
        queryInProgress = true
        latitude = lat
        longitude = lng
        
        pull(lat, lng: lng)
    }
    
    func get() { // for geting the next page of results...not setup to work with foursquare atm...
        if(results.count == 0) {
            return
        }
        
        pull(latitude, lng: longitude)
    }
    
    func pull(lat : Double, lng : Double) {

        var url = "\(Constants.Foursquare.API.search)"
            url += "?ll=\(lat),\(lng)"
            url += "&v=20160417"
            url += "&client_id=" + Constants.Foursquare.id
            url += "&client_secret=" + Constants.Foursquare.secret
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPMethod = "GET"
        task = session.downloadTaskWithRequest(request)
        task!.resume()
    }
    
    // Download in progress.
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    }
    
    // Download complete with error.
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if(error != nil) {
            //print("DEBUG: download completed with error")
        }
    }
    
    // Download complete.
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        
        let data = NSData(contentsOfURL: location)!
        NSOperationQueue.mainQueue().addOperationWithBlock({
            //print(String.init(data: data, encoding:NSUTF8StringEncoding))
            self.processResponse(data)
        })
    }
    
    func clear() {
        if(queryInProgress == false) {
            foundResults = false
            results = []
        }
    }
    
    func processResponse(data : NSData) {
        do {
            let jsonData = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! Dictionary<String, AnyObject>
            
            for (k, v) in jsonData {
                if k == "response" {
                    let venues = v["venues"] as! Array<AnyObject>
                    for nthVenue in venues {
                        
                        let new : Venue = Venue()
                        
                        for (k,v) in nthVenue as! Dictionary<String,AnyObject> {
                            
                            if k == "categories" {
                                
                                let categories = v as! Array<AnyObject>
                                
                                if categories.count > 0 {
                                    let firstCategory = categories.first as! Dictionary<String,AnyObject>
                                    new.category = firstCategory["name"] as! String
                                    let i = firstCategory["icon"] as! Dictionary<String,AnyObject>
                                    let prefix = i["prefix"] as! String
                                    let suffix = i["suffix"] as! String
                                    new.icon_url = prefix + "32" + suffix
                                 }
                                
                            } else if k == "location" {
                              
                                let location = v as! Dictionary<String,AnyObject>
                                new.lat = location["lat"] as! Double
                                new.lng = location["lng"] as! Double
                                
                            } else {
                                
                                if new.respondsToSelector(Selector(k)) && !NSObject.respondsToSelector(Selector(k)) {
                                    new.setValue(v, forKey: k)
                                }
                            }
                        
                        }
                        
                        results.append(new)
                        
                        let moc = getMOC()
                        let venue = NSEntityDescription.insertNewObjectForEntityForName("Venue", inManagedObjectContext:moc)
                        
                        venue.setValue(new.id, forKey:"id")
                        venue.setValue(new.name, forKey:"name")
                        venue.setValue(new.category, forKey:"category")
                        venue.setValue(new.lat, forKey:"lat")
                        venue.setValue(new.lng, forKey:"lng")
                        venue.setValue(new.icon_url, forKey:"icon_url")
                        venue.setValue(new.thumb_url, forKey:"thumb_url")
                        
                        do {
                            try moc.save()
                        } catch {
                            print("There is some error.")
                        }
                    }
                    
                }
            }
        } catch {
            NSLog("JSON serialization failed!")
        }
        
        if results.count > 0 {
            foundResults = true
        } else {
            print("Search returned no results or encountered an error.")
        }
        
        queryInProgress = false
    }
    
    func getMOC() -> NSManagedObjectContext {
        let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        return appDelegate!.managedObjectContext
    }
    
    let pi = 3.14159265358979323846
    let earthRadiusKm = 6371.0
    let MIinKM = 0.62137119
    
    func deg2rad(deg: Double) -> Double {
        return (deg * pi / 180)
    }
    
    func rad2deg(rad: Double) -> Double {
        return (rad * 180 / pi)
    }
    
    func calcuateDistance(lat1: Double, lng1: Double, lat2: Double, lng2: Double) -> Double {
        
        let lat1r = deg2rad(lat1)
        let lon1r = deg2rad(lng1)
        let lat2r = deg2rad(lat2)
        let lon2r = deg2rad(lng2)
        let u = sin((lat2r - lat1r)/2)
        let v = sin((lon2r - lon1r)/2)
        return 2.0 * earthRadiusKm * asin(sqrt(u * u + cos(lat1r) * cos(lat2r) * v * v)) // in KM
    }
    
    func getDistance(venue: Venue) -> String {
        var raw = calcuateDistance(venue.lat, lng1: venue.lng, lat2: latitude, lng2: longitude)
            raw *= MIinKM
        return String(format: "%0.1f", raw)
    }
    
    deinit {
        
        //delete
        /*
         // Delete places from core data.
         let fetchRequest = NSFetchRequest(entityName: DataController.instance.data_entity as String)
         let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
         
         do {
         NSLog("Deleting old results from core data.")
         try moc.executeRequest(deleteRequest)
         try moc.save()
         } catch {
         print (error)
         }
         */
        
        //fetch
        /*
         let fetchRequest = NSFetchRequest(entityName: DataController.instance.data_entity)
         
         places.lat = defaults.doubleForKey("lat")
         places.lng = defaults.doubleForKey("lng")
         
         do {
         let results =
         try moc.executeFetchRequest(fetchRequest) as! [PlaceManaged] //[NSManagedObject]
         
         for r in results {
         let place : Place = Place()
         
         place.formatted_address = r.formatted_address
         place.lat = r.lat
         place.lng = r.lng
         place.name = r.name
         
         places.add(place)
         }
         
         if(places.results.count > 0) {
         NSLog("Sucessfully pulled stored results from core data.")
         places.success = true
         }
         
         } catch let error as NSError {
         print("Could not fetch \(error), \(error.userInfo)")
         }*/
        
        //insert
        /*
         if hasMoved == true {
         for p in places.results {
         let managedPlace = NSEntityDescription.insertNewObjectForEntityForName(DataController.instance.data_entity, inManagedObjectContext: moc) as! PlaceManaged
         
         managedPlace.setValue(p.formatted_address, forKey: "formatted_address")
         managedPlace.setValue(p.lat, forKey: "lat")
         managedPlace.setValue(p.lng, forKey: "lng")
         managedPlace.setValue(p.name, forKey: "name")
         }
         
         do {
         try moc.save()
         NSLog("Saving places to core data.")
         } catch let error as NSError {
         NSLog("Failed to save to core data (\(error))")
         }
         }
         */
        
    }
}