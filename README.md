# DynamicBlurView

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/DynamicBlurView.svg?style=flat)](http://cocoadocs.org/docsets/DynamicBlurView)
[![License](https://img.shields.io/cocoapods/l/DynamicBlurView.svg?style=flat)](http://cocoadocs.org/docsets/DynamicBlurView)
[![Platform](https://img.shields.io/cocoapods/p/DynamicBlurView.svg?style=flat)](http://cocoadocs.org/docsets/DynamicBlurView)

DynamicBlurView is a dynamic and high performance UIView subclass for Blur.

#### [Appetize's Demo](https://appetize.io/app/9pvxr367tm0jj2bcy8zavxnqkg?device=iphone6&scale=75&orientation=portrait)

* Demo gif  
![Gif](https://github.com/KyoheiG3/assets/blob/master/DynamicBlurView/home.gif)

* Image capture  
![Gif](https://github.com/KyoheiG3/assets/blob/master/DynamicBlurView/home.png)


* Since using the CADisplayLink, it is a high performance.
* UIToolbar does not use.
* Can generate a plurality of BlurView.

## How to Install DynamicBlurView

### iOS 8+

#### Cocoapods

Add the following to your `Podfile`:

```Ruby
pod "DynamicBlurView"
use_frameworks!
```
Note: the `use_frameworks!` is required for pods made in Swift.

#### Carthage

Add the following to your `Cartfile`:

```Ruby
github "KyoheiG3/DynamicBlurView"
```

### iOS 7

Just add everything in the `DynamicBlurView.swift` file to your project.


## Usage

### import

If target is ios8.0 or later, please import the `DynamicBlurView`.

```Swift
import DynamicBlurView
```

### Example

Blur the whole

```swift
let blurView = DynamicBlurView(frame: view.bounds)
blurView.blurRadius = 10
view.addSubview(blurView)
```

Animation

```swift
UIView.animateWithDuration(0.5) {
    blurView.blurRadius = 30
}
```

### Variable

```Swift
var blurRadius: CGFloat
```
* Strength of the blur.

```Swift
var dynamicMode: DynamicBlurView.DynamicMode
```
* Mode for update frequency.
* `Common` is constantly updated.
* `Tracking` is only during scrolling update.  
* `None` is not update.

```swift
var blendColor: UIColor?
```
* Blend in the blurred image.

```swift
var iterations: Int
```
* Number of times for blur.
* Default is 3.

```swift
var fullScreenCapture: Bool
```
* Please be on true if the if Layer is not captured. Such as UINavigationBar and UIToolbar. Can be used only with DynamicMode.None.
* Default is false.

```swift
var blurRatio: CGFloat
```
* Ratio of radius.
* Defauot is 1.  


### Function

```swift
func refresh()
```
* Get blur image again. for DynamicMode.None

```swift
func remove()
```
* Delete blur image. for DynamicMode.None


## Acknowledgements

* Inspired by [FXBlurView](https://github.com/nicklockwood/FXBlurView) in [nicklockwood](https://github.com/nicklockwood).

## LICENSE

Under the MIT license. See LICENSE file for details.
