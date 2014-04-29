#!/bin/bash
# This is an alternative build strategy to produce an offline Maven Repo.
# It's not strictly needed since building at root level with just "mvn clean install" will produce an
# offline maven repo using "karaf features plugin"

MAVEN_OFFLINE_TMP=/tmp/mvn_offline

rm -rf $MAVEN_OFFLINE_TMP

mvn clean install \
    -DskipTests \
    -Pdependency-plugin \
    -Dmaven.repo.local=$MAVEN_OFFLINE_TMP

