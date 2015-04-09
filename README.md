# DynamicBlurView

[![Carthage Compatibility](https://img.shields.io/badge/carthage-✓-f2a77e.svg?style=flat)](https://github.com/Carthage/Carthage/)
[![Version](https://img.shields.io/cocoapods/v/DynamicBlurView.svg?style=flat)](http://cocoadocs.org/docsets/DynamicBlurView)
[![License](https://img.shields.io/cocoapods/l/DynamicBlurView.svg?style=flat)](http://cocoadocs.org/docsets/DynamicBlurView)
[![Platform](https://img.shields.io/cocoapods/p/DynamicBlurView.svg?style=flat)](http://cocoadocs.org/docsets/DynamicBlurView)

DynamicBlurView is a dynamic and high performance UIView subclass for Blur.

* Demo gif  
![Gif](https://github.com/KyoheiG3/assets/blob/master/DynamicBlurView/blur_view.gif)

* Image capture  
![Gif](https://github.com/KyoheiG3/assets/blob/master/DynamicBlurView/blur_view.png)


* Since using the CADisplayLink, it is a high performance.
* UIToolbar does not use.
* Can generate a plurality of BlurView.

## How to Install DynamicBlurView

### iOS 8+

#### Using Carthage

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
Animation block is always updated.

```swift
var iterations: Int
```
* Number of times for blur.

## Acknowledgements

* Inspired by [FXBlurView](https://github.com/nicklockwood/FXBlurView) in [nicklockwood](https://github.com/nicklockwood).

## LICENSE

Under the MIT license. See LICENSE file for details.
