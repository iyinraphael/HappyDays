//
//  ViewController.swift
//  HappyDays
//
//  Created by Iyin Raphael on 2/10/20.
//  Copyright © 2020 Iyin Raphael. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    @IBOutlet weak var helpLabel: UILabel!
    
    @IBAction func requestPermission(_ sender: Any) {
        
        requestPhotosPermissions()
    }
    
// Mark: - Permission for Photo library, Audio record permission and for Speech
    func requestPhotosPermissions() {
        PHPhotoLibrary.requestAuthorization { [unowned self] authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.requestRecordPersmissions()
                } else {
                    self.helpLabel.text = "Photos permission was declined; please enable it in settings the tap again."
                }
            }
        }
    }
    
    func requestRecordPersmissions() {
        AVAudioSession.sharedInstance().requestRecordPermission {  [unowned self] allowed in
            DispatchQueue.main.async {
                if allowed {
                    self.requestTranscibedPermission()
                } else {
                    self.helpLabel.text = "Recording permission was declined; please enable it in settings then tap continue again."
                }
            }
        }
    }
    
    func requestTranscibedPermission() {
        SFSpeechRecognizer.requestAuthorization { [unowned self] authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.authorizationComplete()
                } else {
                    self.helpLabel.text = "Transcription permission was declinedd; please enable it in settings then tap Continue again."
                }
            }
        }
    }
    
    func authorizationComplete() {
        dismiss(animated: true, completion: nil)
    }

}

