//
//  MemoriesViewController.swift
//  HappyDays
//
//  Created by Iyin Raphael on 3/14/20.
//  Copyright © 2020 Iyin Raphael. All rights reserved.
//

import UIKit
import Photos
import Speech

class MemoriesViewController: UICollectionViewController {
    
    // MARK: - Properties
    var memories = [URL]()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        checkPermissions()
    }
    
    func checkPermissions () {
        let photosAuthoprized = PHPhotoLibrary.authorizationStatus() == .authorized
        let recorddingAuthorized = AVAudioSession.sharedInstance().recordPermission == .granted
        let transcribedAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        
        let authorized = photosAuthoprized && recorddingAuthorized && transcribedAuthorized
        
        if authorized == false {
            if let vc = storyboard?.instantiateViewController(identifier: "FirstRun") {
                navigationController?.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - Methods
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        
        return documentsDirectory
    }
    
    func loadMemories() {
        memories.removeAll()
        
        // attempt to load all the memories in our documents directory
        guard let files = try? FileManager.default.contentsOfDirectory(at: getDocumentsDirectory(),
                                                                       includingPropertiesForKeys: nil,
                                                                       options: [])
            else { return }
        
        // loop over every file found
        for file in files {
            let filename = file.lastPathComponent
            

            // check it ends with ".thumb" wso we don't count each memory more than once
            if filename.hasSuffix(".thumb") {
                // get the root name of the memory (i.e., without its path expansion)
                let noExtension = filename.replacingOccurrences(of: ".thumb", with: "")
                
                // create a full path from the memory
                let memoryPath = getDocumentsDirectory().appendingPathComponent(noExtension)
                
                // add it our array
                memories.append(memoryPath)
            }
            // reload our list of memories
            collectionView.reloadSections(IndexSet(integer: 1))
        }
        
    }

}
