//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by mac on 2/3/17.
//  Copyright © 2017 Alder. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class FlickrClient: NSObject {
    
    var session = URLSession.shared
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    
    
    
    func getImagesFromFlickr(pin:Pin, completionHandler: @escaping (_ result: [String]?, _ error: NSError?) -> Void) {
        
        //creating serching box from long and lat
        let minimumLon = max(Double(pin.long) - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(Double(pin.lat) - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(Double(pin.long) + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(Double(pin.lat) + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        let bbox =  "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
        //creating array of methid parameters
        let methodParameters = setMethodParameters(bbox: bbox) as [String:AnyObject]
        //creating url for request
        let url = flickrURLFromParameters(parameters: methodParameters)
        getPagesNumber(url: url) { result, error in
            guard let pages = result else {
                print("error")
                return
            }
            let maxPages = 4000 / Int(Constants.FlickrParameterValues.PerPage)!
            let pageLimit = min(pages, maxPages)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            var methodParametersWithPageNumber = methodParameters
            methodParametersWithPageNumber[Constants.FlickrParameterKeys.Page] = randomPage as AnyObject?
            var urlWithPageNumber = self.flickrURLFromParameters(parameters: methodParametersWithPageNumber)
            print(urlWithPageNumber)
            self.getImagesURLandSetImageObjects(url: urlWithPageNumber, pin: pin) { (result, error) in
                guard let result = result else {
                    return
                }
                completionHandler(result, nil)
            }
        }
        
        
    }
    
    
    private func flickrURLFromParameters(parameters: [String:AnyObject]) -> URL {
        let components = NSURLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        return components.url!
    }
    
    
    func setMethodParameters(bbox:String) -> [String : AnyObject] {
        
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bbox,
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
            Constants.FlickrParameterKeys.PerPage: Constants.FlickrParameterValues.PerPage
        ]
        return methodParameters as [String : AnyObject]
        //  displayImageFromFlickrBySearch(methodParameters: methodParameters as [String : AnyObject])
    }
    
    
    
    
    func getImagesURLandSetImageObjects(url: URL,pin:Pin, completionHandler: @escaping (_ result: [String]?, _ error: NSError?) -> Void) {
        
        var urlArray = [String]()
        getDataFromFlickr(url: url) { result, error in
            
            guard let photosDictionary = result else {
                print("\(error)")
                return
            }
            guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                print("Cannot find key '\(Constants.FlickrResponseKeys.Photo)' in \(photosDictionary)")
                return
            }
            if photosArray.count == 0 {
                print("No Photos Found. Search Again.")
                return
            } else {
                var numOfPicForDownload = 21
                if photosArray.count < numOfPicForDownload {
                    numOfPicForDownload = photosArray.count
                }
                var num = 0
                while num < numOfPicForDownload {
                    let photoDictionary = photosArray[num] as [String: AnyObject]
                    let photoTitle = photoDictionary[Constants.FlickrResponseKeys.Title] as? String
                    print(photoTitle)
                    
                    /* GUARD: Does our photo have a key for 'url_m'? */
                    guard let imageUrlString = photoDictionary[Constants.FlickrResponseKeys.MediumURL] as? String else {
                        print("Cannot find key '\(Constants.FlickrResponseKeys.MediumURL)' in \(photoDictionary)")
                        return
                    }
                    urlArray.append(imageUrlString)
                    DispatchQueue.main.async {
                        var newImage = Image.init(imageURL: imageUrlString, imageData: nil, context: self.stack.context)
                        newImage.toPin = pin
                    }
                    num += 1
                }
                self.stack.save()
                completionHandler(urlArray, nil)
            }
            
            
        }
    }
    
    
    func getPagesNumber(url:URL,completionHandler: @escaping (_ result: Int?, _ error: NSError?) -> Void) {
        getDataFromFlickr(url: url) { result, error in

            /* GUARD: Is "pages" key in the photosDictionary? */
            guard let result = result else {
                return
            }
            guard let totalPages = result[Constants.FlickrResponseKeys.Pages] as? Int else {
                print("Cannot find key '\(Constants.FlickrResponseKeys.Pages)' in \(result)")
                return
            }
            completionHandler(totalPages,nil)
        }
    }
    
    
    
    
    func getDataFromFlickr(url: URL, completionHandler: @escaping (_ result: [String:AnyObject]?, _ error: NSError?) -> Void) {
        
        // create session and reques)t
        let request = URLRequest(url: url)
        
        
        // create network request
        let task = session.dataTask(with: request) { (data, response, error) in
            
            // if an error occurs, print it and re-enable the UI
            func displayError(error: String) {
                print(error)
                DispatchQueue.main.async {
                    //  self.setUIEnabled(true)                }
                }
            }
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                displayError(error: "There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                displayError(error: "Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                displayError(error: "No data was returned by the request!")
                return
            }
            
            // parse the data
            self.convertDataWithCompletionHandler(data: data) { (result, error) in
                guard (error == nil) else {
                    //    completionHandler(nil, "Data error. Try again later")
                    return
                }
                guard let result = result else {
                    //    completionHandler(nil,"Data error. Try again later")
                    return
                }
                guard let photosDictionary = result[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                    displayError(error: "Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' in \(result)")
                    return
                }
                completionHandler(photosDictionary, nil)
            }
        }
        task.resume()
    }
    
    
    // MARK: - assist functions
    func convertDataWithCompletionHandler(data: Data, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        var parsedResult: AnyObject! = nil
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        completionHandlerForConvertData(parsedResult, nil)
    }
    
    func getImagesDataFor(pin:Pin) {
        let imagesArray = Array(pin.toImage!)
        for image in imagesArray {
            getImageDataFor(image: image as! Image)
        }
    }
    
    func getImageDataFor(image:Image) {
        let url = URL(string: image.imageURL)!
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { (data, response, error) in
            guard (error == nil) else {
                print("There was an error with the task for image")
                return
            }
            guard let data = data else {
                print("data error")
                return
            }
            DispatchQueue.main.async {
                image.imageData = data
                self.stack.save()
            }
        }
        task.resume()
    }
    
    // MARK: -  Singleton
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
    
    
    
    
}
