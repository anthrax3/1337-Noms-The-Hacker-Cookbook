#!/bin/bash
#
# Author: @theDevilsVoice
#
# Date: 10/13/2017
#
# Script Name: makebook.sh
#
# Description: Use this shell script to ensure your system
#              is ready for the class.
#
# Run Information:
#
# Error Log: Any output found in /path/to/logfile

BUILD_DIR=/tmp/cookbook

#Black        0;30     Dark Gray     1;30
#Red          0;31     Light Red     1;31
#Green        0;32     Light Green   1;32
#Brown/Orange 0;33     Yellow        1;33
#Blue         0;34     Light Blue    1;34
#Purple       0;35     Light Purple  1;35
#Cyan         0;36     Light Cyan    1;36
#Light Gray   0;37     White         1;37

RED='\033[0;31m'
LRED='\033[1;31m'
LGREEN='\033[1;32m'
CYAN='\033[0;36m'
LPURP='\033[1;35m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color


function remove_stale {

  if [ -d "${BUILD_DIR}.old" ]
  then 
    rm -rf ${BUILD_DIR}.old
  fi 

  if [ -d "${BUILD_DIR}" ] 
  then 
    mv ${BUILD_DIR} ${BUILD_DIR}.old
    echo "Renaming stale directory in /tmp."
  fi
  return 0

  mkdir ${BUILD_DIR}

} # //remove_stale

function check_installed() {
 
  PACKAGE=$1

  if [ $(dpkg-query -W -f='${Status}' ${PACKAGE} 2>/dev/null | grep -c "ok installed") -eq 0 ];
  then
    echo -e "${LPURP}Installing package: ${PACKAGE}"
    echo -e "${NC}"
    sudo apt-get -y install ${PACKAGE}
  else
    echo -e "${LPURP}Found package: ${PACKAGE}"
    echo -e "${NC}"
  fi
 
  return 0
} # //check_installed 

#############################
# Do stuff for Debian based #
#############################
function debian {

  BASE_DIR=${PWD}
  THEMES_DIR="${BUILD_DIR}/local/lib/python2.7/site-packages/markdown2pdf/themes"

  # Python3
  check_installed python3-venv 
  check_installed python3-dev
  
  #/usr/bin/python3 -m venv ${BUILD_DIR}
  /usr/bin/python3 ./makebook.py 

  if [ -f "${BUILD_DIR}/output.md" ]
  then
    echo -e "${LGREEN}"
    echo "Successfully generated Markdown file"
    echo -e "${NC}"
  else
    echo -e "${YELLOW}"
    echo "Cannot find output.md, check makebook.py"
    echo -e "${NC}"
    exit 1
  fi
  # Python2
  pip install virtualenvwrapper
  /usr/bin/python -m virtualenv ${BUILD_DIR}

  # needed for md2pdf
  check_installed libffi-dev

  cd ${BUILD_DIR} && source bin/activate  

  #
  # https://pypi.python.org/pypi/Markdown2PDF/0.1.3
  #
  pip install wheel
  pip install markdown2pdf

  if [ -f "${BUILD_DIR}/output.md" ] 
  then 
    echo -e "${LPURP}"
    echo "Building PDF..."
    echo -e "${NC}"
    #md2pdf ${BUILD_DIR}/output.md
    #md2pdf ${BUILD_DIR}/output.md --theme ${BASE_DIR}/github.css
    md2pdf ${BUILD_DIR}/output.md --theme ${BASE_DIR}/style.css
    #md2pdf output.md --theme=path_to_style.css
  else 
    echo -e "${YELLOW}" 
    echo "Cannot find output.md, check makebook.py"  
    echo -e "${NC}"
    exit 1
  fi 
 
  if [ -f "${BUILD_DIR}/output.pdf" ] 
  then 
    cp ${BUILD_DIR}/output.pdf ${BASE_DIR}/hacker_cookbook.pdf
    echo -e "${LGREEN}"
    echo "Success!"
    echo -e "${NC}"
  else 
    echo -e "${YELLOW}"
    echo "Could not find ${BUILD_DIR}/output.pdf"
    echo -e "${NC}"
    exit 1
  fi
  cd ${BASE_DIR} && rm -rf ${BUILD_DIR}
  deactivate 
  return 0

} # //debian()

#######################
# Do stuff for RedHat #
#######################
function redhat {

  return 0
}

########################
# Do stuff for FreeBSD #
########################

########################
# Do stuff for OpenBSD #
########################
function obsd {

  return 0
}

######################
# Do Stuff for Apple #
######################
function apple {
  brew install cairo pango gdk-pixbuf libxml2 libxslt libffi
  return 0
}

function main {

  remove_stale 

  if [ "$(uname)" == "Darwin" ]; then
    apple
  elif [ "$(uname)" == "OpenBSD" ]; then
    obsd
  elif [ "$(grep -Ei 'fedora|redhat' /etc/*release)" ]; then
    redhat
  elif [ "$(grep -Ei 'debian|buntu|mint' /etc/*release)" ]; then
    debian
  else
    echo "Unable to run on this architecture"
    exit 1
  fi

} # //main()

if [ -z "$ARGS" ] ; then
  main $@
else
  main $ARGS
fi
