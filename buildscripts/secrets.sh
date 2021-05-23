#!/bin/bash

#check if env-vars.sh exists
if [ -f ./buildscripts/env-vars.sh ]
then
	source ./buildscripts/env-vars.sh
fi
#no `else` case needed if the CI works as expected

# AppSecrets
sourcery --config ./buildscripts/configs/appsecrets.yml
