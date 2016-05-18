/*
 Charlie Mathews, 2016
 This work is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License
 */

import UIKit
import CoreLocation

class ListViewController: UITableViewController, CLLocationManagerDelegate {

    let locationManager : CLLocationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadObservers()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        
        refreshControl = UIRefreshControl()
        refreshControl!.backgroundColor = UIColor.grayColor()
        refreshControl!.tintColor = UIColor.whiteColor()
        refreshControl!.addTarget(self, action: #selector(updateLocation), forControlEvents: .ValueChanged)
        
        updateLocation()
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        updateLocation()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        print("Found location.")
        
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
            print(venues.results.count)
            refreshControl?.endRefreshing()
        }
        
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if (venues.results.count>0) {
            
            self.tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
            return 1
            
        } else {
            
            /*
            UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
            
            messageLabel.text = @"No data is currently available. Please pull down to refresh.";
            messageLabel.textColor = [UIColor blackColor];
            messageLabel.numberOfLines = 0;
            messageLabel.textAlignment = NSTextAlignmentCenter;
            messageLabel.font = [UIFont fontWithName:@"Palatino-Italic" size:20];
            [messageLabel sizeToFit];
            
            self.tableView.backgroundView = messageLabel;
            self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
            */
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}

