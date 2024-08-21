#!/bin/bash

pushd "$(dirname "$0")" > /dev/null

export GRADLE_USER_HOME=$(pwd)/guh

GRADLE_DISTRIBUTION_URL=https\://services.gradle.org/distributions
DISTRIBUTION_TYPE=bin

function section() {
    echo ""
    echo "################################################################################"
    echo "$1"
    echo "################################################################################"
}

function print_wrapper_info() {
  echo "Current Distribution URL: $(grep "distributionUrl" gradle/wrapper/gradle-wrapper.properties | cut -d '=' -f 2 | awk -F- '{print $2}')"
  print_wrapper_jar_version
}

function current_wrappers() {
  tree guh/wrapper/dists -d -L 2
}

function print_wrapper_jar_version() {
  checksum=$(shasum -a 256 gradle/wrapper/gradle-wrapper.jar | cut -d ' ' -f 1)
  case $checksum in
    "575098db54a998ff1c6770b352c3b16766c09848bee7555dab09afc34e8cf590")
      version="7.4"
      ;;
    "91a239400bb638f36a1795d8fdf7939d532cdc7d794d1119b7261aac158b1e60")
      version="7.5"
      ;;
    "14dfa961b6704bb3decdea06502781edaa796a82e6da41cd2e1962b14fbe21a3")
      version="7.6.2"
      ;;
    "d3b261c2820e9e3d8d639ed084900f11f4a86050a8f83342ade7b6bc9b0d2bdd")
      version="8.5/8.6"
      ;;
    "cb0da6751c2b753a16ac168bb354870ebb1e162e9083f116729cec9c781156b8")
      version="8.7"
      ;;
    *)
      version="Unknown Version"
      ;;
  esac
  echo "Current Wrapper Jar:      $version"
}

section "Cleaning Gradle User Home ($GRADLE_USER_HOME)"
echo "Are you sure you want to delete Gradle User Home ($GRADLE_USER_HOME)? [y/N]"
read -r response
case "$response" in
    [yY][eE][sS]|[yY])
        rm -rf "$GRADLE_USER_HOME"
        ;;
    *)
        # If the user does not confirm, do not delete and print a message
        echo "Operation cancelled by user"
        exit 1
        ;;
esac

section "Beginning State"
echo "Reverting gradle directory"
git checkout -- gradle
git checkout -- gradlew
git checkout -- gradlew.bat
print_wrapper_info
echo "Gradle Versions to be requested:"
sed 's/^/- /' gradle_versions.txt
echo ""

for line in $(cat gradle_versions.txt); do
    for i in {1..2}; do
        section "Gradle Version: $line - Attempt: $i"
        print_wrapper_info
        current_wrappers
        echo "Requesting Gradle Version: $line"
        ./gradlew --quiet wrapper --gradle-version $line --gradle-distribution-url=$GRADLE_DISTRIBUTION_URL/gradle-$line-$DISTRIBUTION_TYPE.zip
    done
done

for line in $(cat gradle_versions.txt); do
    section "Project with Gradle Version: $line"
    pushd sample-projects/$line > /dev/null
    ./gradlew help --quiet
    popd > /dev/null
done

current_wrappers

popd > /dev/null # $(dirname "$0")