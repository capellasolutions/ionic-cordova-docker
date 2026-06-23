# Ionic Cordova App Builder
So this is a project that should help you produce an Android project and build, or/and an Xcode project for iOS, using Docker only. It is basically a set of command lines that make it easier for you to produce the final app build.

These files can be placed inside an Ionic project to use.

## Repository layout
* `app-builder.Dockerfile` — builds the heavy **toolchain base image** (Ubuntu + JDK + Android SDK + Node + Cordova/Ionic CLIs). Build it once and reuse it; that's why it is a separate image.
* `Dockerfile` — `FROM app-builder`, copies your app in and runs `ionic cordova build`. This is the per-app build.
* `build-mobile.sh` — convenience wrapper that builds both images and copies the artifact out.
* `example-app/` — a stock Ionic starter you can **clone and build immediately** to test the pipeline end-to-end. It carries its **own copies** of the three files above so it is self-contained (Docker can't reach files outside its build context, so the copies are required, not accidental). The root files are the source of truth; the `example-app` copies of `Dockerfile` and `app-builder.Dockerfile` are kept byte-for-byte identical (CI enforces this). `example-app/build-mobile.sh` is intentionally slightly different (it uses `version=0.0.0` and comments out `docker push`).

To try it out right away:
```shell
cd example-app
./build-mobile.sh
```

## Usage
**First** you need to build and push the builder image. It is separated so you don't waste time rebuilding it every time you build a new app.
Use the following commands:
```shell
docker build . -f ./app-builder.Dockerfile -t app-builder
docker push app-builder
```
Optionally, you can use `--build-arg` like

```shell
docker build . -f ./app-builder.Dockerfile \
  --build-arg PACKAGE_MANAGER=yarn \
  --build-arg ANDROID_PLATFORMS_VERSION=36 \
  -t app-builder
```

*Note: You can change `app-builder` with whatever name you like, but you need to change it as well inside `Dockerfile` (the `FROM app-builder` line).*

Docker builder arguments (defaults shown):
* `GRADLE_VERSION`: Gradle version installed in the image and used for the Cordova wrapper. Default `8.14.5` (cordova-android 15 uses an AGP 8.x plugin, so stay on Gradle 8.x).
* `JAVA_VERSION`: JDK version. Default `21` (LTS). cordova-android 13–15 officially document JDK 17, but AGP 8.x / Gradle 8.5+ also run on JDK 21; JDK 25 would need AGP 9 / Gradle 9.1+.
* `ANDROID_PLATFORMS_VERSION`: Android platform (compile/target SDK) to install. Default `36`.
* `ANDROID_BUILD_TOOLS_VERSION`: Android build-tools version. Default `36.0.0`.
* `ANDROID_SDK_TOOLS_VERSION`: Android command-line tools build number. Default `14742923`.
* `PACKAGE_MANAGER`: `npm`, `yarn`, or `pnpm` (yarn and pnpm are provided via Corepack). Default `npm`. Also selects how `Dockerfile` installs *your app's* dependencies (`npm ci`/`yarn install --frozen-lockfile`/`pnpm install --frozen-lockfile`), so make sure the matching lockfile (`package-lock.json`/`yarn.lock`/`pnpm-lock.yaml`) is committed.
* `NODE_VERSION`: Node.js major (installed via NodeSource). Default `24` (current LTS).
* `YARN_VERSION`: Yarn version prepared through Corepack. Default `stable`.
* `PNPM_VERSION`: pnpm version prepared through Corepack. Default `latest`.
* `USER`: helpful for permissions. Default `ionic`.
* `CORDOVA_VERSION`: Cordova CLI version. Default `13.0.0`.
* `IONIC_CLI_VERSION`: Ionic CLI version. Default `7.2.1`.

> Check the [Android Platform Guide](https://cordova.apache.org/docs/en/latest/guide/platforms/android/) first, make sure you have a matching `cordova-android` in `package.json`, and that `<preference name="android-targetSdkVersion" value="X" />` in `config.xml` matches `ANDROID_PLATFORMS_VERSION`.

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
* `PACKAGE_ID`: the bundleId you use for your app.
* `ENV_NAME`: `prod` or `dev`, depending on what your environment files are called inside the `environments` folder.
* `PLATFORM`: `ios` or `android`, or both using `all`.
* `VERSION`: optional override for the version specified inside `config.xml`. See `Dockerfile` and uncomment the line that sets it.

**Finally**, to get the build out of that image:
For the Android build:
```shell
docker run --user root:root --privileged=true -v ./build-output:/app/mount:Z --rm --entrypoint cp app-build -r ./output/android /app/mount
```

For the iOS build (note: iOS can only be *prepared* on Linux, never compiled — finish the build on macOS; run `pod install` if you use firebasex):
```shell
docker run --user root:root --privileged=true -v ./build-output:/app/mount:Z --rm --entrypoint cp app-build -r ./output/ios /app/mount
cd ./build-output/ios && pod repo update && pod install
```

There is a `build-mobile.sh` file if you want to run all these steps from a shell (you can comment out the first part later).

## Continuous integration
`.github/workflows/build.yml` runs on push/PR and:
1. checks the `example-app` Docker copies haven't drifted from the root files,
2. lints, builds and unit-tests the demo app, and
3. builds the toolchain image and the demo Android app end-to-end.

`.github/dependabot.yml` keeps the demo's npm dependencies, the Docker base images, and the GitHub Actions up to date.

Good Luck 🧡

[Al-Mothafar Al-Hasan](https://github.com/almothafar) from
[Capella Solutions](https://www.capellasolutions.com/)
