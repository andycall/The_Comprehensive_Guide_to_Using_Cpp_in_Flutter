# Setting up an Develop and Debugging Environment for your C/C++ project with Flutter Apps —- Guide Part II

For an flutter app developments, it's easy to set up an development and debugger environment with Dart using Code or Jetbrains IDE. 

But using C/C++ in Flutter, things will be more different, because the offical Dart & Flutter IDE plugins was not designed for C/C++ developments.

For developing and debugging C/C++ in multiple variaty of operation systems, we needs to config and step up different IDE for each of platforms as follows:

They are many develop environments for C/C++ projects. We can use Xcode for iOS and macOS, Android Studio for Android, Visual Studio for Windows and other IDE tools for Linux platforms.

In my personal working experience, the best development IDE that I had used for most of the time is JetBrains's Clion, which providing the universal development experiences for each platforms. 

For developers who using C/C++ in Flutter apps, it's normal to deploy and sharing the same code base for all platform with different operating system and CPU archs. For using the same IDE, it's more convenient for reusing your experiences for using these tools.

## Config your C/C++ project with Clion

Clion has built-in support for CMake projects, to setup Clion with intellisense, you needs to open the project fold which contains the `CMakeLists.txt` file, it our example project, that will be `<project_root>/src`:

![setup_clion](./imgs/setup_clion.png)

The clion will config your C/C++ projects based on your CMake config automatically. 

### Debugging your Flutter Apps with Clion

It's easier to debugging and Flutter apps with Clion on desktop platforms, including macOS, Windows and Linux.

It's also recommend to developing your C/C++ codes on desktop first, then cross-compile them and running on mobile platforms.

**Start an Flutter apps with Clion LLDB Debugger**

At first, you needs to compile your flutter apps:

```bash
flutter build macos --debug
```

After your flutter apps compiled, the app will generated at `<project_root>/example/build/macos/Build/Products/Debug/flutter_native_example_example.app`.

> For Linux or Windows platform, just looking for your flutter apps located under `<project_root>/example/build/` directory.

**Add an Debugger configuration in Clion**

Open your Clion, click the `Editr Configurations` selection menu on the top:


![Edit Configuration](./imgs/add%20config.png)

Click the `+` button on top left, and select the `Native Application`:

![Add native application](./imgs/add_native_application.png)

Remove the default `Build` configure on the middle bottom, and then click dropdown menu with `Executable:` tag:

![Add Executable](./imgs/add_executable.png)

Find and select the executable file for your Flutter apps in `<project_root>/example/build/` directory.

![Target](./imgs/target.png)

The selection results will be as follows:

![Clion](./imgs/clion_result.png)

Now it's ready for debugging, Click the debug icon on the topbar to starting your debugging:

![alt text](./imgs/clion_debugging.png)

**Attach an running application with Clion Debugger**

If your application had started earlyer than clion debugger, you can attach an exist running flutter apps with the `Attach To Process` Feature in Clion:

![Attach To Process](./imgs/clion_attach_to_process.png)

## Debugging C/C++ Codes in XCode

XCode is an alternative IDE for C/C++ debugging for macOS and iOS platforms, first of all, opening the `Runner.xcworkspace` project in XCode.

The source codes of our C/C++ codes were not visible in XCode by default, so we needs additional setup to make it visible and allow use setting breakpoint on it:

In Xcode, right click at the `Runner` Project, select `Add Files to "Runner"`:

![Xcode Add File](./imgs/xcode_add_file.png)

Select the source fold that contains `CMakeLists.txt`, but keeping reminds that unselect all targets in the bottom, because we didn't wants XCode to package our C/C++ codes in our project.

![Add Files](image.png)

Now we can set breakpoints in xcode and debugging the C++ source codes:

![Debugging in XCode](image-1.png)