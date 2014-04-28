#!/bin/bash
MAVEN_OFFLINE_TMP=/tmp/mvn_offline
rm -rf $MAVEN_OFFLINE_TMP
mvn clean install \
    -DskipTests \
    -Pdependency-plugin \
    -Dmaven.repo.local=$MAVEN_OFFLINE_TMP

