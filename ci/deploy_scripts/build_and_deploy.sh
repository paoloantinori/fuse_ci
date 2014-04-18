#!/bin/bash
(cd ../../ ; mvn clean install -DskipTests -Dmaven.test.skip) ;  sh deploy_docker.sh