/*
 Charlie Mathews, 2016
 This work is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License
 */

import UIKit
import CoreLocation

class ListViewController: UITableViewController, CLLocationManagerDelegate {

    let locationManager : CLLocationManager = CLLocationManager()
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadObservers()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        
        refreshControl = UIRefreshControl()
        refreshControl!.backgroundColor = Constants.Colors.statusBar
        refreshControl!.tintColor = UIColor.whiteColor()
        refreshControl!.addTarget(self, action: #selector(updateLocation), forControlEvents: .ValueChanged)
        
        updateLocation()
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        venues.get()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        //print("Found location.")
        if locations.count > 0 {
            let lat = locations[0].coordinate.latitude
            let lng = locations[0].coordinate.longitude
            venues.get(lat, lng: lng)
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Unable to find location.")
        NSLog(error.description)
        print("Searching from Winnetka, IL")
        venues.get(42.101844, lng: -87.731731) //<wpt lat="42.101844" lon="-87.731731">
    }
    
    func updateLocation() {
        switch CLLocationManager.authorizationStatus() {
            
        case .AuthorizedWhenInUse, .AuthorizedAlways:
            locationManager.requestLocation()
            
        case .NotDetermined:
            locationManager.requestWhenInUseAuthorization()
            
        case .Restricted, .Denied:
            let alertController = UIAlertController(
                title: "Location Access Disabled",
                message: "For this app to function, please open settings and allow location access.",
                preferredStyle: .Alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            let openAction = UIAlertAction(title: "Open Settings", style: .Default) { (action) in
                if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                    UIApplication.sharedApplication().openURL(url)
                }
            }
            alertController.addAction(openAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func loadObservers() {
        venues.addObserver(self, forKeyPath: "foundResults", options: Constants.KVO_Options, context: nil)
    }
    
    deinit {
        venues.removeObserver(self, forKeyPath: "foundResults")
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        if keyPath == "foundResults" && venues.foundResults == true {
            tableView.reloadData()
            refreshControl?.endRefreshing()
        }
        
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if (venues.results.count>0) {
            
            tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
            tableView.backgroundView = nil
            return 1
            
        } else {
            
            let message = UILabel(frame: CGRectMake(0,0,self.view.bounds.size.width, self.view.bounds.size.height))
            message.text = "Loading..."
            message.textColor = UIColor.blackColor()
            message.numberOfLines = 0
            message.textAlignment = NSTextAlignment.Center
            
            tableView.backgroundView = message
            tableView.separatorStyle = UITableViewCellSeparatorStyle.None
            
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return venues.results.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("venue", forIndexPath: indexPath) as! VenueCell
        
        cell.name.text = venues.results[indexPath.row].name
        
        let distance = Double(venues.results[indexPath.row].distance)*0.000621371
        cell.distance.text = "\(String(format: "%0.1f", distance)) miles away"
        
        let isOpen = !venues.results[indexPath.row].is_closed
        if isOpen {
            cell.status.text = "OPEN"
            cell.status.textColor = UIColor.greenColor()
        } else {
            cell.status.text = "CLOSED"
            cell.status.textColor = UIColor.grayColor()
        }
        
        return cell
    }
    
    func loadImage(index : Int) {
        let url = venues.results[index].image_url
        if let checkedURL = NSURL(string: url) {
            //media.results[index].coverData.item = index
            //media.results[index].coverData.addObserver(self, forKeyPath: "imageDownloadComplete", options: Constants.KVO_Options, context: nil)
            //media.results[index].coverData.get(checkedURL)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}

