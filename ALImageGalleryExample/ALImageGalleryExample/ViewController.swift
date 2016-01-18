//
//  ViewController.swift
//  ALImageGalleryExample
//
//  Created by Aldo Rangel on 1/5/16.
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Aldo Pedro Rangel Montiel
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import UIKit
import ALImageGallery

class ViewController: UIViewController {
    var images:[UIImage] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        prepareImages()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func prepareImages(){
        images.append(UIImage(named: "tv-test")!)
        images.append(UIImage(named: "sydney.jpg")!)
        images.append(UIImage(named: "bear.jpg")!)
    
    }
    
    @IBAction func showImagesOnlyGallery(){
        let imageGallery = ALImageGalleryViewController(images: images)
        imageGallery.dismissWhenSlidesUp = true
        self.presentViewController(imageGallery, animated: true, completion: nil)
        
    }
    
    
    @IBAction func showImagesFrom2ndIndexGallery(){
        let imageGallery = ALImageGalleryViewController(images: images, selectedIndex: 1)
        imageGallery.dismissWhenSlidesUp = true
        self.presentViewController(imageGallery, animated: true, completion: nil)
        
    }
    
    


}

