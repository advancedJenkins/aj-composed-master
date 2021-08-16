#!/bin/bash

set -e

clear

function initAjScript {
    BG_RED='\033[0;41;93m'
    BG_GREEN='\033[0;31;42m'
    BG_BLUE='\033[0;44;93m'
    BLUE='\033[0;94m'
    YELLOW='\033[0;93m'
    NC='\033[0m' # No Color

    rm -rf temp 2> /dev/null | true
    mkdir -p temp
}

function initAjConfig {
    echo "#!/bin/bash" > temp/aj.config
    echo -e "" >> temp/aj.config
}

function inputVariable {

    TITLE=$1
    VARIABLE_NAME=$2
    VALUE=${!VARIABLE_NAME}
    echo -e -n "${TITLE}\n\t[${BLUE}${VALUE}${NC}]? "
    read -r
    if [[ "$REPLY" != "" ]]; then
        VALUE="$REPLY"
    fi
    echo "export $VARIABLE_NAME=${VALUE}" >> temp/aj.config
    export $VARIABLE_NAME=${VALUE}
}

function inputTextVariable {

    TITLE=$1
    VARIABLE_NAME=$2
    VALUE=${!VARIABLE_NAME}
    echo -e -n "${TITLE}\n\t[${BLUE}${VALUE}${NC}]? "
    read -r
    if [[ "$REPLY" != "" ]]; then
        VALUE="$REPLY"
    fi
    echo "export $VARIABLE_NAME='${VALUE}'" >> temp/aj.config
    export $VARIABLE_NAME='${VALUE}'
}

initAjScript
initAjConfig

inputVariable "aj-master Docker image" AJ_MASTER_VERSION
inputVariable "advancedJenkins host IP address (set to * for automatic IP calculation)" AJ_HOST_IP
inputVariable "Jenkins server HTTP port" JENKINS_HTTP_PORT_FOR_SLAVES
inputVariable "Jenkins JNLP port for slaves" JENKINS_SLAVE_AGENT_PORT
inputTextVariable "advancedJenkins customization folder root path" AJ_CUSTOMIZATION_FOLDER
inputVariable "Number of executers on master" JENKINS_ENV_EXECUTERS
inputTextVariable "advancedJenkins banner title" AJ_MASTER_TITLE_TEXT
inputVariable "advancedJenkins banner title color" AJ_MASTER_TITLE_COLOR
inputVariable "AppCyadvancedJenkinscles banner background color" AJ_MASTER_BANNER_COLOR

cp temp/aj.config aj.config


