#!/bin/bash

GRADLE_DISTRIBUTION_URL=https\://services.gradle.org/distributions
DISTRIBUTION_TYPE=bin

for line in $(cat gradle_versions.txt); do
    for i in {1..2}; do
        ./gradlew wrapper --gradle-version $line --gradle-distribution-url=$GRADLE_DISTRIBUTION_URL/gradle-$line-$DISTRIBUTION_TYPE.zip
    done
done