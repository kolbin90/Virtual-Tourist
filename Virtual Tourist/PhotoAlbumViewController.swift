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
    var insertedIndexPaths = [IndexPath]()
    var deletedIndexPaths = [IndexPath]()
    var updatedIndexPaths = [IndexPath]()
    var selectedIndexPaths = [IndexPath]()
    var pinForImages:Pin!
    var editingMode = false
    var fetchedResultsController: NSFetchedResultsController<Image>!
    var itemCount:Int? // to resolve bug. Read more: https://fangpenlin.com/posts/2016/04/29/uicollectionview-invalid-number-of-items-crash-issue/

    // MARK: - Oulets
    
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var reloadButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.showAnnotations([pin!], animated: true)
        pinForImages = findPinInCoreData()
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let space: CGFloat = 2.0
        let size = self.collectionView.frame.size
        let dimension:CGFloat = (size.width - (4 * space)) / 3.0
        let flowLayout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        flowLayout.sectionInset = UIEdgeInsets(top: space, left: space, bottom: space, right: space)
        collectionView.collectionViewLayout = flowLayout
        // self.collectionView?.scrollToItem(at: IndexPath(row: 0, section: 0),at: .top, animated: false)
    }
    
    // MARK: - Controller Delegate
    
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
            if self.collectionView.numberOfSections == 0 {
                self.collectionView.reloadData()
            } else {
                if self.updatedIndexPaths.count == 0 {
                    self.itemCount! = self.itemCount! + self.insertedIndexPaths.count - self.deletedIndexPaths.count
                }
                self.collectionView.performBatchUpdates(
                {
                    () -> Void in
                    for indexPath in self.insertedIndexPaths {
                        self.collectionView.insertItems(at: [indexPath])
                       // self.itemCount! += 1
                    }
                    for indexPath in self.deletedIndexPaths {
                        self.collectionView.deleteItems(at: [indexPath])
                        //self.itemCount! -= 1
                    }
                    for indexPath in self.updatedIndexPaths {
                        self.collectionView.reloadItems(at: [indexPath])
                    }
            }
                ,completion: nil)
                
                self.insertedIndexPaths = [IndexPath]()
                self.deletedIndexPaths = [IndexPath]()
                self.updatedIndexPaths = [IndexPath]()
        }
        }
    }
    
    // MARK: - CollectionView delegate
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let items = itemCount {
            if items > 0 {
                label.isHidden = true
            } else {
                label.isHidden = false
            }
            return items
        } else {
            if let sections = fetchedResultsController.sections  {
                let sectionInfo = sections[section]
                if sectionInfo.numberOfObjects > 0 {
                    label.isHidden = true
                } else {
                    label.isHidden = false
                }
                itemCount = sectionInfo.numberOfObjects
                return itemCount!
            }
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)  as! PhotoAlbumCell
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if editingMode {
            if let index = selectedIndexPaths.index(of: indexPath) {
                selectedIndexPaths.remove(at: index)
            } else {
                selectedIndexPaths.append(indexPath)
            }
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)  as! PhotoAlbumCell
            configureCell(cell, atIndexPath: indexPath)
            collectionView.reloadItems(at: [indexPath])

            
        }
    }
    
    
    // MARK: - Assist functions
   
    func configureCell(_ cell: PhotoAlbumCell, atIndexPath indexPath: IndexPath) {
        let image = fetchedResultsController.object(at: indexPath)
<<<<<<< HEAD
        if let imageData = image.imageData {
            cell.imageCell!.image = UIImage(data: imageData)
        } else {
            cell.imageCell!.image = #imageLiteral(resourceName: "placeholder")
        }
        
        if let _ = selectedIndexPaths.index(of: indexPath) {
            cell.alpha = 0.5
        } else {
            cell.alpha = 1
        }
||||||| merged common ancestors
        let imageData = image.imageData!
        cell.imageCell!.image = UIImage(data: imageData)
=======
        cell.imageCell?.image = nil
        if let imageData = image.imageData {
            cell.imageCell!.image = UIImage(data: imageData)
        } else {
            cell.imageCell!.image = #imageLiteral(resourceName: "placeholder")
        }
        
        if let _ = selectedIndexPaths.index(of: indexPath) {
            cell.alpha = 0.5
        } else {
            cell.alpha = 1
        }
>>>>>>> newDownload
    }
    
    
    func findPinInCoreData() -> Pin? {
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
        //pinForImages.removeFromToImage(pinForImages.toImage!)
        let arrayOfImages = Array(pinForImages.toImage!)
        DispatchQueue.main.async {
            for image in arrayOfImages {
                self.stack.context.delete(image as! NSManagedObject)
            }
           // self.itemCount! = 0
            self.stack.save()
        }
        FlickrClient.sharedInstance().getImagesFromFlickr(pin: pinForImages) { (result, error) in
            DispatchQueue.main.async {
                if let result = result {
                    FlickrClient.sharedInstance().getImagesDataFor(pin: self.pinForImages)
                    self.stack.save()
                }
            }
        }
    }
    
    // MARK:- Actions
    
    @IBAction func deleteButton(_ sender: Any) {
        for indexPath in selectedIndexPaths {
            let image = fetchedResultsController.object(at: indexPath) as! Image
            stack.context.delete(image)
        }
        stack.save()
        selectedIndexPaths = []
    }
    
    @IBAction func reloadButton(_ sender: Any) {
        newData()
    }
    
    @IBAction func editButton(_ sender: Any) {
        if editingMode {
            selectedIndexPaths = []
            collectionView.reloadData()
            editingMode = false
            editButton.title = "Edit"
        } else {
            editingMode = true
            editButton.title = "Done"
        }
            deleteButton.isEnabled = editingMode
            reloadButton.isEnabled = editingMode
    }
}
