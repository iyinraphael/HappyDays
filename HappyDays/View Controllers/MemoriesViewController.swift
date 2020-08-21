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

class MemoriesViewController: UICollectionViewController, UINavigationControllerDelegate {
    
    // MARK: - Properties
    var memories = [URL]()
    var activeMemory: URL!
    
    var audioRecorder: AVAudioRecorder?
    var recordingURL: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadMemories()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
        
        recordingURL = getDocumentsDirectory().appendingPathComponent("recording.m4a")
    }
    
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
    
    // MARK: - Collection View
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 0
        } else {
            return memories.count
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Memory", for: indexPath) as! MemoryCell
        
        let memory = memories[indexPath.row]
        let imageName = thumbnailURL(for: memory).path
        let image = UIImage(contentsOfFile: imageName)
        cell.imageView.image = image
        // place gestureRecognize over cell
        if cell.gestureRecognizers == nil {
            let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(memoryLongPress))
            recognizer.minimumPressDuration = 0.25
            cell.addGestureRecognizer(recognizer)
            
            cell.layer.borderColor = UIColor.white.cgColor
            cell.layer.borderWidth = 3
            cell.layer.cornerRadius = 10
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath)
    }

    
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
            
            // check it ends with ".thumb" so we don't count each memory more than once
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
    
    func saveNewMemory(image: UIImage) {
        // create a unique name for this memory
        let memoryName = "memory-\(Date().timeIntervalSince1970)"
        
        // use the unique name to create fileames for the full-size image and the thumbnail
        let imageName = memoryName + ".jpg"
        let thumbnailName = memoryName + ".thumb"
        
        do {
            // create a URL where we can write the JPEG to
            let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
            
            // convert the UUImage into a JPEG data object
            if let jpegData = image.jpegData(compressionQuality: 0.8) {
                
                // write that data to the URL we created
                try jpegData.write(to: imagePath, options: [.atomicWrite])
            }
            
            // create thumbnail here
            if let thumbnail = resize(image: image, to: 200) {
                let imagePath = getDocumentsDirectory().appendingPathComponent(thumbnailName)
                
                if let jpegData = thumbnail.jpegData(compressionQuality: 0.8){
                    try jpegData.write(to: imagePath, options: [.atomicWrite])
                }
            }
        } catch {
            print("Failed to save to disk.")
        }
        
    }
    
    func resize(image: UIImage, to width: CGFloat) -> UIImage? {
        // calculate how much we need to bring the width down to match our target size
        let scale = width / image.size.width
        
        // bring the height down by the same amount so that the aspect ratio is preserved
        let height = image.size.height * scale
        
        // create a new image context we can draw into
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
        
        // draw the original iamge into the context
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // pull ou the resized version
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // end the context so UIKit can clean up
        UIGraphicsEndImageContext()
        
        // sne it back to the caller
        return newImage
        
    }
    
    func imageURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("jpg")
    }
    
    func thumbnailURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("thumb")
    }
    
    func audioURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("m4a")
    }
    
    func transcriptionURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("txt")
    }
    
    @objc func addTapped() {
           let vc = UIImagePickerController()
           vc.modalPresentationStyle = .formSheet
           vc.delegate = self
           navigationController?.present(vc, animated: true)
       }
       
    @objc func memoryLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let cell = sender.view as! MemoryCell
            
            if let index = collectionView.indexPath(for: cell){
                activeMemory = memories[index.row]
                recordMemory()
            }
        } else if sender.state == .ended {
            finishRecording(success: true)
        }
    }
    
    func recordMemory() {
        collectionView?.backgroundColor = UIColor(red: 0.5, green: 0, blue: 0, alpha: 1)
        
        // this just save me writing AVAudioSession.sharedIntance() everywhere
        let recordingSession = AVAudioSession.sharedInstance()
        
        do {
            // configure the session for recording and playback through the speaker
            try recordingSession.setCategory(.playback, mode: .default, options: .defaultToSpeaker)
            try recordingSession.setActive(true)
            
            // set up a high-quality recording session
            let settings = [ AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                             AVSampleRateKey: 44100,
                             AVNumberOfChannelsKey: 2,
                             AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
            
            // create the audio recording, and assign ourselves as the delgate
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
        
        } catch let error {
            print("failed to record: \(error)")
            finishRecording(success: false)
        }
    }
    
    func finishRecording(success: Bool) {
        collectionView?.backgroundColor = UIColor.darkGray
        
        // Stop the recording if it isn’t already stopped.
        audioRecorder?.stop()
        
        if success {
            do {
                // If the recording was successful, we need to create a file URL out of the active memory URL plus “m4a”
                let memoryAudioURL = activeMemory.appendingPathExtension("m4a")
                let fm  = FileManager.default
                
                // If a recording already exists there, we need to delete it because you can’t move a file over one that already exists.
                if fm.fileExists(atPath: memoryAudioURL.path) {
                    try fm.removeItem(at: memoryAudioURL)
                }
                // Move our recorded file (stored at the URL we put in recordingURL) into the memory’s audio URL.
                try fm.moveItem(at: recordingURL, to: memoryAudioURL)
                
                // Start the transcription process.
                transcribeAudo(memory: activeMemory)
           
            } catch let error {
               
                print("Failure finsihing recording: \(error)")
            }
        }
        
    }
    
    func transcribeAudo(memory: URL) {
        // get paths to where the audio is, and where the transcription should be
        let audio = audioURL(for: memory)
        let transcription = transcriptionURL(for: memory)
        
        // create a new recognizer and point it at our audio
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: audio)
        
        // start recognition!
        recognizer?.recognitionTask(with: request) { [unowned self ] (result, error) in
            // abort if we didn't get any transcription back
            guard let result = result else {
                print("There was an error: \(error!)")
                return
            }
            // if we go the final transcription back, we need to write to disk
            if result.isFinal {
                // pull out the best transcription...
                let text = result.bestTranscription.formattedString
                
                // ...and write it to disk at the correct filename for this memory.
                do {
                    try text.write(to: transcription, atomically: true, encoding: String.Encoding.utf8)
                } catch {
                    print("Failed to save transcription")
                }
            }
        }
    }
}

    // MARK: - Delagates method

extension MemoriesViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true)
        
        if let possibleImage = info[.originalImage] as? UIImage {
            saveNewMemory(image: possibleImage)
            loadMemories()
        }
    }
}

extension MemoriesViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 1{
            return CGSize.zero
        } else {
            return CGSize(width: 0, height: 50)
        }
    }
}

extension MemoriesViewController: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
}
