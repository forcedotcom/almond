#!/bin/bash
TARGET_TO_RUN="$1"
#JAVA_HOME="/System/Library/Frameworks/JavaVM.framework/Versions/1.5.0/Home"
#ANT_HOME=${BUILD_TOOLS_HOME}"/ant/apache-ant-1.7.1"
#PATH=$JAVA_HOME/bin:$ANT_HOME/bin:$PATH

echo  "Executing : ${TARGET_TO_RUN}"
ant ${TARGET_TO_RUN} -DcheckOnly=false -DrunAllTests=true -f build.xml