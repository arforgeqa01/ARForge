//
//  DeviceImageFetcher.swift
//  ARForge
//
//  Created by ARForgeQA on 9/1/21.
//

import Foundation
import Combine
import Photos
import AVKit
import MobileCoreServices
import CommonCrypto

enum LibraryStatus {
    case unknown
    case denied
    case approved
    case limited
}

struct Asset: Identifiable, Hashable {
    var id = UUID().uuidString
    var asset: PHAsset
    var image: UIImage
}

enum SetupState {
    case notStarted
    case pending
    case finished
}

class DeviceImageFetcher: NSObject, ObservableObject {
    static let shared = DeviceImageFetcher()
    @Published var library_status = LibraryStatus.unknown
    @Published var fetchedAssets : [Asset] = []
    @Published var allPHAssets : PHFetchResult<PHAsset>!
    @Published var setupState = SetupState.notStarted
    let fetchAndConvertDG = DispatchGroup()
    
    func setupIfNeeded() {
        guard  setupState == .notStarted else {
            return
        }
        
        setupState = .pending
        
        // requesting Permission...
        PHPhotoLibrary.requestAuthorization(for: .readWrite) {[self] (status) in
            
            DispatchQueue.main.async {
                
                switch status{
                
                case .denied: library_status = .denied
                case .authorized: library_status = .approved
                case .limited: library_status = .limited
                default : library_status = .denied
                }
                
                if library_status != .denied {
                    fetchAssets()
                } else {
                    setupState = .finished
                }
            }
        }
        
        // Registering Observer...
        PHPhotoLibrary.shared().register(self)
    }
    
    func fetchAssets(){
        
        // Fetching All Photos...
        
        let options = PHFetchOptions()
        options.sortDescriptors = [
        
            // Latest To Old...
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        options.includeHiddenAssets = false
        
        let fetchResults = PHAsset.fetchAssets(with: options)
        
        allPHAssets = fetchResults
        
        fetchResults.enumerateObjects {[self] (asset, index, _) in
            
            // Getting Image From Asset...
            fetchAndConvertDG.enter()
            getThumbnailImageFromAsset(asset: asset) { image in
                // Appending it To Array...
                
                // Why we storing asset..
                // to get full image for sending....
                
                fetchedAssets.append(Asset(asset: asset, image: image))
                fetchAndConvertDG.leave()
            }
        }
        
        fetchAndConvertDG.notify(queue: .main) { [self] in
            setupState = .finished
        }
    }
    
    func getThumbnailImageFromAsset(asset: PHAsset,completion: @escaping (UIImage)->()){
        
        let size = CGSize(width: 150, height: 150 * asset.pixelHeight/asset.pixelWidth)
        
        // To cache image in memory....

        let imageManager = PHCachingImageManager()
        imageManager.allowsCachingHighQualityImages = true
        
        // Your Own Properties For Images...
        let imageOptions = PHImageRequestOptions()
        imageOptions.deliveryMode = .highQualityFormat
        imageOptions.isSynchronous = false
        
        
        imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: imageOptions) { (image, _) in
            
            guard let resizedImage = image else{return}
            
            completion(resizedImage)
        }
    }
    
}

extension DeviceImageFetcher: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        guard let _ = allPHAssets else{return}
        
        if let updates = changeInstance.changeDetails(for: allPHAssets){
            
            // Getting Updated List...
            let updatedPhotos = updates.fetchResultAfterChanges
            
            // There is bug in it...
            // It is not updating the inserted or removed items....
            
//            print(updates.insertedObjects.count)
//            print(updates.removedObjects.count)
            
            // So were Going to verify All And Append Only No in the list...
            // To Avoid Of reloading all and ram usage...
            
            updatedPhotos.enumerateObjects {[self] (asset, index, _) in
                
                if !allPHAssets.contains(asset){
                    
                    // If its not There...
                    // getting Image And Appending it to array...
                    
                    getThumbnailImageFromAsset(asset: asset) { (image) in
                        DispatchQueue.main.async {
                            fetchedAssets.append(Asset(asset: asset, image: image))
                        }
                    }
                }
            }
            
            // To Remove If Image is removed...
            allPHAssets.enumerateObjects { (asset, index, _) in
                
                if !updatedPhotos.contains(asset){
                    
                    // removing it...
                    DispatchQueue.main.async {
                        
                        self.fetchedAssets.removeAll { (result) -> Bool in
                            return result.asset == asset
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.allPHAssets = updatedPhotos
            }
        }
    }
}

// Helper functions
extension DeviceImageFetcher {
    
    static func getMimeType(asset: PHAsset) -> String {
        if let pathExtension = PHAssetResource.assetResources(for: asset).first?.originalFilename.split(separator: ".")[1],
           let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                let fileMimeType = mimetype as String
                return fileMimeType
            }
        }
        return "application/octet-stream"
    }
    
    static func sha1(data: Data) -> String {
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0, CC_LONG(data.count), &digest)
        }
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        return hexBytes.joined()
    }
    
    static func exportDataPublisher(asset: Asset, isThumbnail: Bool = false) -> AnyPublisher<(Data,String,String), Error> {
        let subject: PassthroughSubject<(Data,String, String), Error> = .init()
        
        DispatchQueue.main.async {
            if  isThumbnail,
               let data = asset.image.pngData() {
                let mimeType = "image/png"
                subject.send((data, mimeType, sha1(data: data)))
            } else if asset.asset.mediaType == .image {
                exportImageData(asset: asset.asset) { data in
                    if let data = data {
                        subject.send((data, self.getMimeType(asset: asset.asset), sha1(data: data)))
                    }
                }
            } else if asset.asset.mediaType == .video {
                exportVideoData(asset: asset.asset) { data in
                    if let data = data {
                        subject.send((data, "video/mp4", sha1(data: data)))
                    }
                }
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    static func exportImageData(asset: PHAsset, completion: @escaping (Data?)->()) {
        
        let imageManager = PHCachingImageManager()
        
        let imageOptions = PHImageRequestOptions()
        imageOptions.deliveryMode = .highQualityFormat
        imageOptions.isSynchronous = false
        
        imageManager.requestImageDataAndOrientation(for: asset, options: imageOptions) { data, _, _, _ in
            completion(data)
        }
    }
    
    static func exportVideoData(asset: PHAsset, completion: @escaping (Data?)->()) {
        let manager = PHCachingImageManager()

        let videoManager = PHVideoRequestOptions()
        videoManager.deliveryMode = .highQualityFormat
        
        manager.requestAVAsset(forVideo: asset, options: videoManager) { (videoAsset, _, _) in
            
            guard let videoAsset = videoAsset else{
                completion(nil)
                return
            }
            
            DispatchQueue.main.async {
                
                let fileName = PHAssetResource.assetResources(for: asset).first?.originalFilename ?? NSUUID().uuidString
                let filePathURL = FileManager.default.urls(for: .documentDirectory,
                                                                  in: .userDomainMask)[0].appendingPathComponent(fileName)

                let exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetHighestQuality)
                exportSession?.outputURL = filePathURL
                exportSession?.outputFileType = .mp4
                
                exportSession?.exportAsynchronously(completionHandler: {
                    let data = try? Data(contentsOf: filePathURL)
                    try? FileManager.default.removeItem(at: filePathURL)
                    completion(data)
                })
            }
        }
    }
}
