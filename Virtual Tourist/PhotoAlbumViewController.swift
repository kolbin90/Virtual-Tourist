//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by mac on 2/4/17.
//  Copyright © 2017 Alder. All rights reserved.
//

import UIKit
import CoreData
import MapKit


class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    // MARK: - Variables
    var pin: MKAnnotation!
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!
    var pinForImages:Pin!
    var editingMode = false
    var fetchedResultsController: NSFetchedResultsController<Image>!

    // MARK: - Oulets
    
    @IBOutlet weak var reloadButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.showAnnotations([pin!], animated: true)
        pinForImages = findPin()!
        fetchedResultsController = {
            let fetchRequest: NSFetchRequest<Image> = Image.fetchRequest()
            let predicate = NSPredicate.init(format: "toPin == %@", argumentArray: [pinForImages])
            let sortDescriptor = NSSortDescriptor(key: "toPin", ascending: false)
            fetchRequest.predicate = predicate
            fetchRequest.sortDescriptors = [sortDescriptor]
            let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
            frc.delegate = self
            return frc
        }()
        do {
            try fetchedResultsController.performFetch()
        }
        catch let error as NSError {
            print("An error occured \(error) \(error.userInfo)")
        }
    }
    
    // MARK: - Controller Delegate
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type{
            
        case .insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .update:
            updatedIndexPaths.append(indexPath!)
            break
        case .move:
            print("Move an item. We don't expect to see this in this app.")
            break
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.async {
            self.collectionView.performBatchUpdates(
                {
                    () -> Void in
                    for indexPath in self.insertedIndexPaths {
                        self.collectionView.insertItems(at: [indexPath])
                    }
                    for indexPath in self.deletedIndexPaths {
                        self.collectionView.deleteItems(at: [indexPath])
                    }
                    for indexPath in self.updatedIndexPaths {
                        self.collectionView.reloadItems(at: [indexPath])
                    }
            }
                ,completion: nil)
        }
    }
    
    // MARK: - CollectionView delegate
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            let sectionInfo = sections[section]
            return sectionInfo.numberOfObjects
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        configureCell(cell as! PhotoAlbumCell, atIndexPath: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if editingMode {
            let selectedImage = fetchedResultsController.object(at: indexPath)
            stack.context.delete(selectedImage)
            stack.save()
        }
    }
    
    // MARK: - Assist functions
    
    func configureCell(_ cell: PhotoAlbumCell, atIndexPath indexPath: IndexPath) {
        let image = fetchedResultsController.object(at: indexPath)
        let imageData = image.imageData!
        cell.imageCell!.image = UIImage(data: imageData)
    }
    
    func findPin() -> Pin? {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        let coordinates = [Float(pin.coordinate.latitude),Float(pin.coordinate.longitude)]
        let predicate = NSPredicate.init(format: "(lat == %@) AND (long == %@)", argumentArray: coordinates)
        fr.predicate = predicate
        if let result = try? stack.context.fetch(fr) {
            return result[0] as? Pin
        } else {
            print("error with fetching")
            return nil
        }
    }
    
    func newData() {
        pinForImages.removeFromToImage(pinForImages.toImage!)
        FlickrClient.sharedInstance().getImagesFromFlickr(long: Float(pin.coordinate.longitude), lat: Float(pin.coordinate.latitude)) { (result, error) in
            print("Vodnikov LLIac \(result?.count)")
            DispatchQueue.main.async {
                if let result = result {
                    print("oi oi oi OLLIu6ka")
                    FlickrClient.sharedInstance().saveToCore(imagesData: result, forPin: self.pin)
                    self.stack.save()
                }
            }
        }
    }
    
    // MARK:- Actions
    
    @IBAction func reloadButton(_ sender: Any) {
        newData()
    }
    
    @IBAction func editButton(_ sender: Any) {
        if editingMode {
            editingMode = false
            editButton.title = "Edit"
        } else {
            editingMode = true
            editButton.title = "Done"
        }
            reloadButton.isEnabled = editingMode
    }
}
