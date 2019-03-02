#!/bin/sh

#  pod_install.sh
#
#
#  Created by Vlad Soroka on 6/15/16.
#

cd "${0%/*}"
fastlane beta patch:true adhoc:true
