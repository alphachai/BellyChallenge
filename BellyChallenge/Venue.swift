/*
 Charlie Mathews, 2016
 This work is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License
 */


import Foundation

class Venue : NSObject {
    
    var id : String = ""
    var name : String = ""
    var lat : Double = 0
    var lng : Double = 0
    var category : String = ""
    var icon_url : String = ""
    var icon_data : ImageData = ImageData()
    
    var thumb : ImageData = ImageData()
}