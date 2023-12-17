<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

# focused_area_ocr_flutter

This is a package to get text in the focused area on the camera.<br>
It is created based on OCR technology by [google_mlkit_text_recognition](https://pub.dev/packages/google_mlkit_text_recognition).

## Features
With this package, you can get the text in the focused area on the camera.<br>
![image](https://github.com/KobayashiYoh/focused_area_ocr_flutter/assets/82624334/3c691e63-1ee7-43b2-bb50-775e47c62a64)


## Getting started

### iOS
Add the following code to `ios/Runner/Info.plist`.
```
<key>NSCameraUsageDescription</key>
<string>your usage description here</string>
<key>NSMicrophoneUsageDescription</key>
<string>your usage description here</string>
```

Edit `ios/Runner/Info.plist` as follows.
```ruby
platform :ios, '12.0'  # or newer version

...

# add this line:
$iOSVersion = '12.0'  # or newer version

post_install do |installer|
  # add these lines:
  installer.pods_project.build_configurations.each do |config|
    config.build_settings["EXCLUDED_ARCHS[sdk=*]"] = "armv7"
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = $iOSVersion
  end
  
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # add these lines:
    target.build_configurations.each do |config|
      if Gem::Version.new($iOSVersion) > Gem::Version.new(config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'])
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = $iOSVersion
      end
    end
    
  end
end
```

### Android
Edit `android/app/build.gradle` and set the following sdk version.
- minSdkVersion: 21
- targetSdkVersion: 33
- compileSdkVersion: 33

## Usage
This is an example of a Flutter project using focused_area_ocr_flutter.
See [example](https://github.com/shinonome-inc/focused_area_ocr_flutter/tree/develop/example) for details.

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:focused_area_ocr_flutter/focused_area_ocr_view.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final StreamController<String> controller = StreamController<String>();
  final double _textViewHeight = 80.0;

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).viewPadding.top;
    final Offset focusedAreaCenter = Offset(
      0,
      (statusBarHeight + kToolbarHeight + _textViewHeight) / 2,
    );
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          FocusedAreaOCRView(
            onScanText: (text) {
              controller.add(text);
            },
            focusedAreaCenter: focusedAreaCenter,
          ),
          Column(
            children: [
              SizedBox(
                height: statusBarHeight + kToolbarHeight,
                child: AppBar(
                  title: const Text('Focused Area OCR Flutter'),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16.0),
                width: double.infinity,
                height: _textViewHeight,
                color: Colors.black,
                child: StreamBuilder<String>(
                  stream: controller.stream,
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
                    return Text(
                      snapshot.data != null ? snapshot.data! : '',
                      style: const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

<!--
## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
-->
