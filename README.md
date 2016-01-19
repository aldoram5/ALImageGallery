# ALImageGallery

![](https://travis-ci.org/aldoram5/ALImageGallery.svg?branch=master)

A lightweight Image Gallery for iOS written in Swift, it supports zooming the images and paging through them. 
More features will be added in the near future so be sure to comeback.
Licensed under MIT License.


##Installation 

Right now, you could just copy the file **ALImageGallery.swift** into your project, since that's the only file that currently the Gallery needs.

Alternatively, you can clone the repo and drag from the finder window the **ALImageGallery.xcodeproj** to your Xcode project, and link the framework as an embedded binaries and in linked frameworks and libraries.

##Usage

If you are using it as a Framework you must import it first:

```swift
import ALImageGallery
```
And then you can use it like this:

```swift
//prepare the images
var images:[UIImage] = []
images.append(UIImage(named: "image1")!)
images.append(UIImage(named: "image2")!)
images.append(UIImage(named: "image3")!)
//Instantiate the gallery
let imageGallery = ALImageGalleryViewController(images: images)
//present the Gallery
self.presentViewController(imageGallery, animated: true, completion: nil)
```


