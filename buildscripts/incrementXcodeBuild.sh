#! /usr/bin/env bash
# http://www.lanza.io/xcode/2017/03/10/automatically-incrementing-build-numbers.html
location=${PROJECT_DIR}/${INFOPLIST_FILE}
getBuildNumber () {
  echo $(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$location")
  return
}
buildNumber=$[ $(getBuildNumber) + 1 ]
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "$location"
