#!/bin/bash

set -e

function initajScript {
    BG_RED='\033[0;41;93m'
    BG_GREEN='\033[0;31;42m'
    BG_BLUE='\033[0;44;93m'
    BLUE='\033[0;94m'
    BOLDBLUE='\033[1;94m'
    YELLOW='\033[0;93m'
    NC='\033[0m' # No Color

    rm -rf temp 2> /dev/null | true
}

function usage {
    echo -e "\n${BG_BLUE}advancedJenkinscommand usage${NC}\n"
    echo -e "${BLUE}aj.sh${NC} ${BOLDBLUE}<action>${NC} ${BLUE}[option]${NC}"
    echo -e "\n  where ${BOLDBLUE}<action>${NC} is ..."
    echo -e "\t${BOLDBLUE}usage${NC} - show this usage description."
    echo -e "\t${BOLDBLUE}version${NC} - show advancedJenkins-server version information."
    echo -e "\t${BOLDBLUE}status${NC} - show advancedJenkins-server server status & version information."
    echo -e "\t${BOLDBLUE}init${NC} - initialize advancedJenkins-server settings."
    echo -e "\t${BOLDBLUE}start${NC} - start the advancedJenkins-server."
    echo -e "\t${BOLDBLUE}stop${NC} - stop the advancedJenkins-server."
    echo -e "\t${BOLDBLUE}restart${NC} - restart the advancedJenkins-server."
    echo -e "\t${BOLDBLUE}apply${NC} - apply changes in the 'setup' folder on the advancedJenkins-server."
    echo -e "\t${BOLDBLUE}upgrade${NC} ${BLUE}[git-tag]${NC} - upgrage the advancedJenkins-server version. If no git-tag specified, upgrade to the latest on 'master' branch."
    echo -e "\t${BOLDBLUE}log${NC} - tail the docker-compose log."
    echo -e "\t${BOLDBLUE}iptest${NC} - test whether the automatic LAN ip detection works OK."
}

function upgrade {
    if [[ -d customization && ! -d setup ]]; then
        mv customization setup
    fi

    if [[ $# > 1 ]]; then
        version=$2
        git checkout $version 2> /dev/null | true
    else
        version=latest
        git checkout master  2> /dev/null | true
        git pull origin master 2> /dev/null | true
    fi
    hash=`git rev-parse --short=8 HEAD` 2> /dev/null | true
    mkdir -p info/version
    echo -e "[Version]\t${BLUE}${version}${NC}" > info/version/version.txt
    echo -e "[Hash]\t\t${BLUE}${hash}${NC}" >> info/version/version.txt

    echo -e "\n${BG_RED}NOTE:${NC} You need to run again with '${BG_RED}init${NC}' action\n"
}

function ipTest {
    export aj_HOST_IP="$(/sbin/ifconfig | grep 'inet ' | grep -Fv 127.0.0.1 | awk '{print $2}' | head -n 1 | sed -e 's/addr://')"
    echo -e "\nIP: ${BG_BLUE}${aj_HOST_IP}${NC}\n"
}

function setupajScript {
    if [ ! -f aj.config ]; then
        cp templates/aj-server/aj.config.template aj.config
        action='init'
    fi

    source templates/aj-server/aj.config.template
    source aj.config

    if [[ "$action" == "init" ]]; then
        . ./scripts/init-aj.sh
    fi

    mkdir -p cust/docker-compose
    rm -rf setup | true
    mkdir -p setup/docker-compose
    if [ ! -f setup/docker-compose/docker-compose.yml.template ]; then
        cp templates/docker-compose/docker-compose.yml.template setup/docker-compose/docker-compose.yml.template
    fi
    cp -n templates/customized/docker-compose/*.yml cust/docker-compose/ 2> /dev/null | true
    cp -f ${aj_CUSTOMIZATION_FOLDER}/docker-compose/*.yml setup/docker-compose/ 2> /dev/null | true
    echo "# PLEASE NOTICE:" > docker-compose.yml
    echo "# This is a generated file, so any change in it will be lost on the next advancedJenkins action!" >> docker-compose.yml
    echo "" >> docker-compose.yml
    cat setup/docker-compose/docker-compose.yml.template >> docker-compose.yml
    numberOfFiles=`ls -1q setup/docker-compose/*.yml 2> /dev/null | wc -l | xargs`
    if [[ "$numberOfFiles" != "0" ]]; then
        cat setup/docker-compose/*.yml >> docker-compose.yml | true
    fi

    mkdir -p setup/aj-master
    mkdir -p cust/aj-master
    cp -n templates/customized/aj-master/*.yml cust/aj-master/ 2> /dev/null | true
    cp -f templates/aj-master/*.yml setup/aj-master/ 2> /dev/null | true
    cp -f ${AJ_CUSTOMIZATION_FOLDER}/aj-master/*.yml setup/aj-master/ 2> /dev/null | true
    echo "# PLEASE NOTICE:" > aj-master-config.yml
    echo "# This is a generated file, so any change in it will be lost on the next advancedJenkins action!" >> aj-master-config.yml
    echo "" >> aj-master-config.yml
    numberOfFiles=`ls -1q setup/aj-master/*.yml 2> /dev/null | wc -l | xargs`
    cat setup/aj-master/*.yml >> aj-master-config.yml | true

    mkdir -p setup/userContent
    mkdir -p cust/userContent
    cp -n templates/customized/userContent/*.yml cust/userContent/ 2> /dev/null | true
    cp -n templates/userContent/* setup/userContent/ 2> /dev/null | true
    cp -f ${aj_CUSTOMIZATION_FOLDER}/userContent/* setup/userContent/ 2> /dev/null | true
    mkdir -p .data/jenkins_home/userContent
    sed "s/AJ_MASTER_TITLE_TEXT/${AJ_MASTER_TITLE_TEXT}/ ; s/AJ_MASTER_TITLE_COLOR/${AJ_MASTER_TITLE_COLOR}/ ; s/AJ_MASTER_BANNER_COLOR/${AJ_MASTER_BANNER_COLOR}/" templates/aj-server/aj.css.template > setup/userContent/aj.css
    cp setup/userContent/* .data/jenkins_home/userContent 2> /dev/null | true

    mkdir -p setup/files
    cp -n -R templates/files/* setup/files/ 2> /dev/null | true
    cp -R setup/files/* . 2> /dev/null | true

    mkdir -p setup/plugins
    mkdir -p cust/plugins
    cp -n -R templates/plugins/* setup/plugins/ 2> /dev/null | true
    cp -f ${aj_CUSTOMIZATION_FOLDER}/plugins/* setup/plugins/ 2> /dev/null | true
    export JENKINS_ENV_PLUGINS=`awk -v ORS=, '{ print $1 }' setup/plugins/* | sed 's/,$//'`

    if [[ ! -n "$aj_HOST_IP" || "$aj_HOST_IP" == "*" ]]; then
        export aj_HOST_IP="$(/sbin/ifconfig | grep 'inet ' | grep -Fv 127.0.0.1 | awk '{print $2}' | head -n 1 | sed -e 's/addr://')"
    fi

    if [[ "$action" == "init" ]]; then
        exit 0
    fi
}

function info {
    echo -e "\n${BG_BLUE}advancedJenkins MASTER SERVER INFORMATION${NC}\n"
    echo -e "[Server host IP address]\t${BLUE}$aj_HOST_IP${NC}"
    echo -e "[advancedJenkins HTTP port]\t\t\t${BLUE}$JENKINS_HTTP_PORT_FOR_SLAVES${NC}"
    echo -e "[advancedJenkins JNLP port for slaves]\t${BLUE}$JENKINS_SLAVE_AGENT_PORT${NC}"
    echo -e "[Number of master executors]\t${BLUE}$JENKINS_ENV_EXECUTERS${NC}"
}

function version {
    if [[ ! -f info/version/version.txt ]]; then
        version=latest
        mkdir -p info/version
        echo -e "[Version]\t${BLUE}${version}${NC}" > info/version/version.txt
        echo -e "[Hash]\t\t${BLUE}${hash}${NC}" >> info/version/version.txt
    fi
    echo -e "\n${BG_BLUE}advancedJenkins MASTER VERSION INFORMATION${NC}\n"
    cat info/version/version.txt
}

function stopajServer {
   docker-compose down --remove-orphans
   sleep 2
}

function startajServer {
    docker-compose up -d
    sleep 2
}

function showajServerStatus {
    status=`curl -s -I -m 5 http://localhost:$JENKINS_HTTP_PORT_FOR_SLAVES | grep "403" | wc -l | xargs`
    if [[ "$status" == "1" ]]; then
        echo -e "\n${BLUE}[advancedJenkins status] ${BG_GREEN}advancedJenkins-server is up and running${NC}\n"
    else
        status=`curl -s -I -m 5 http://localhost:$JENKINS_HTTP_PORT_FOR_SLAVES | grep "401" | wc -l | xargs`
        if [[ "$status" == "1" ]]; then
            echo -e "\n${BLUE}[advancedJenkins status] ${BG_GREEN}advancedJenkins-server is up and running${NC}\n"
        else
            status=`curl -s -I -m 5 http://localhost:$JENKINS_HTTP_PORT_FOR_SLAVES | grep "503" | wc -l | xargs`
            if [[ "$status" == "1" ]]; then
                echo -e "\n${BLUE}[advancedJenkins status] ${BG_RED}advancedJenkins-server is starting${NC}\n"
            else
                echo -e "\n${BLUE}[advancedJenkins status] ${BG_RED}advancedJenkins-server is down${NC}\n"
            fi
        fi
    fi
}

function tailajServerLog {
    SECONDS=0
    docker-compose logs -f -t --tail="1"  | while read LOGLINE
    do
        echo -e "${BLUE}[ET:${SECONDS}s]${NC} ${LOGLINE}"
        if [[ $# > 0 && "${LOGLINE}" == *"$1"* ]]; then
            pkill -P $$ docker-compose
        fi
    done
}

initajScript

if [[ $# > 0 ]]; then
    action=$1
else
    usage
    exit 1
fi

if [[ "$action" == "iptest" ]]; then
    ipTest
    exit 0
fi

if [[ "$action" == "upgrade" ]]; then
    upgrade
    exit 0
fi

setupajScript

if [[ "$action" == "apply" ]]; then
    tailajServerLog "Running update-config.sh. Done"
    exit 0
fi

if [[ "$action" == "info" ]]; then
    info
    exit 0
fi

if [[ "$action" == "info" || "$action" == "version" ]]; then
    version
    info
    exit 0
fi

if [[ "$action" == "status" ]]; then
    showajServerStatus
    exit 0
fi

if [[ "$action" == "stop" ]]; then
    stopajServer
    showajServerStatus
    exit 0
fi

if [[ "$action" == "restart" ]]; then
    stopajServer
    startajServer
    tailajServerLog "Entering quiet mode. Done..."
    showajServerStatus
    exit 0
fi

if [[ "$action" == "start" ]]; then
    startajServer
    tailajServerLog "Entering quiet mode. Done..."
    showajServerStatus
    exit 0
fi

if [[ "$action" == "log" ]]; then
    tailajServerLog
    exit 0
fi

usage
