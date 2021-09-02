# Ionic Cordova App Builder
So this is a project that should help you produce Android project and build or/and xCode Project for iOS using docker file only, so it is basically a command lines that makes things easier for you to produce the final app build.

These files can be placed inside ionic project to use.

## Usage
**First** you need to build and push builder image, it is separated to save time of rebuild that image everytime you need to build a new app, it is really waste of time if you build that image everytime.
Use the following commands:
```shell
docker build . -f ./app-builder.Dockerfile -t app-builder
docker push app-builder
```
Optionally, you can use `--build-arg` like

```shell
docker build . -f ./app-builder.Dockerfile \
  --build-arg PACKAGE_MANAGER=yarn \
  --build-arg ANDROID_PLATFORMS_VERSION=30 \
  -t app-builder
```

*Note: You can change app-builder with whatever name you like, but you need to change that as well inside `Dockerfile`*

Docker builder Arguments:
* `GRADLE_VERSION`: gradle version you want to use. default is `7.2`
* `JAVA_VERSION`: java sdk version, default is `8`
* `ANDROID_PLATFORMS_VERSION`: android platform version that you want to target, default is 31
* `ANDROID_BUILD_TOOLS_VERSION`: android build tools version that you want to target, default is 31.0.0
* `PACKAGE_MANAGER`: `npm` or `yarn` default is `npm`
* `NODE_VERSION`: Node JS that you desire to use, note that will be effecting npm version, default is `16.8.0` that uses npm 7+
* `YARN_VERSION`: If you use yarn, what is the yarn version default is `1.22.10`
* `USER`: That's helpful for permissions, default is `ionic` 
* `CORDOVA_VERSION`: Cordova cli you want to use default is `10.0.0`
* `IONIC_CLI_VERSION`: Ionic cli that you want to use, default is `6.17.0`


**Then**, you can use your image to build the app:
```shell
docker build . \
  --build-arg ENV_NAME="${ENV_NAME}" \
  --build-arg PACKAGE_ID="${PACKAGE_ID}" \
  --build-arg PLATFORM=${platform} \
  --build-arg VERSION="${version}" \
  -f ./Dockerfile \
  -t app-build
```

Arguments:
* `PACKAGE_ID`: is bundleId that you use for you app
* `ENV_NAME`: prod or dev, depends on what your files ionic project is called inside environments' folder.
* `PLATFORM`: `ios` or `android` or both using `all`
* `VERSION`: optional to override the version that specified inside `config.xml` file, please refer to `Dockerfile` and uncomment the line that specify it.

**Finally** to get the build out of that image:
For Android build:
```shell
docker run --user root:root --privileged=true -v ./build-output:/app/mount:Z --rm --entrypoint cp app-build -r ./output/android /app/mount
```

For iOS build (note you need to do pod install if you have firebasex):
```shell
docker run --user root:root --privileged=true -v ./build-output:/app/mount:Z --rm --entrypoint cp app-build -r ./output/ios /app/mount
cd ./build-output/ios && pod repo update && pod install
```

There is a build-app.sh file if you want to run all these steps using shell (you can comment first part from it later). 

Good Luck 🧡

[Al-Mothafar Al-Hasan](https://github.com/almothafar) from
[Capella Solutions](https://www.capellasolutions.com/)


