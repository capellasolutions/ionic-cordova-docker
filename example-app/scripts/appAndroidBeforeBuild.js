const fs = require('fs');
const path = require('path');

module.exports = (context) => {
  // Make sure android platform is part of build
  if (!context.opts.platforms.includes('android')) {
    return;
  }

  const platformRoot = path.join(context.opts.projectRoot, 'platforms/android');
  const buildGradleFile = path.join(platformRoot, 'build.gradle');
  const projectPropertiesFile = path.join(platformRoot, 'project.properties');
  const cordovaProjectPropertiesFile = path.join(platformRoot, 'CordovaLib/project.properties');

  fs.readFile(buildGradleFile, 'utf8', function (error, data) {
    if (error) {
      return console.error(error);
    }
    const result = data
      .replace(/defaultBuildToolsVersion="29.0.2"/g, 'defaultBuildToolsVersion="30.0.3"')
      .replace(/defaultTargetSdkVersion=29/g, 'defaultTargetSdkVersion=30')
      .replace(/defaultCompileSdkVersion=29/g, 'defaultCompileSdkVersion=30');

    fs.writeFile(buildGradleFile, result, 'utf8', (error) => {
      if (error) {
        return console.error(error);
      }
    });
  });

  fs.readFile(projectPropertiesFile, 'utf8', (error, data) => {
    if (error) {
      return console.error(error);
    }
    const result = data
      .replace(/target=android-29/g, 'target=android-30');

    fs.writeFile(projectPropertiesFile, result, 'utf8', (error) => {
      if (error) {
        return console.error(error);
      }
    });
  });

  fs.readFile(cordovaProjectPropertiesFile, 'utf8', (error, data) => {
    if (error) {
      return console.error(error);
    }
    const result = data
      .replace(/target=android-29/g, 'target=android-30');

    fs.writeFile(cordovaProjectPropertiesFile, result, 'utf8', (error) => {
      if (error) {
        return console.error(error);
      }
    });
  });

  return Promise.resolve().then(() => console.log('Modifying build.gradle and project.properties is done to target SDK 30'))
};
