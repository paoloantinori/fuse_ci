#!/bin/bash

##########################################################################################################
# Description:
#
# helper script to build the project with maven and trigger the creation of the environment using docker
#######################################################################################################

(cd ../../ ; mvn clean install -DskipTests -Dmaven.test.skip) ;  sh deploy_docker.sh