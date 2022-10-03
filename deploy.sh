#!/bin/bash

#
# Powered by VENTO
# https://github.com/VENTO-off/Tomcat-Auto-Deployment
#

#
# Settings
#
GIT_URL="git@github.com:user/example.git"                       # SSH URL to clone git repository
GIT_BRANCH="master"                                             # Branch to deploy
JDK_HOME="/usr/lib/jvm/jdk1.8.0"                                # JDK path (for Maven)
BUILD_SCRIPT="mvn compile package"                              # Script to build image
ORIGINAL_CONFIG_DIR="/opt/configs/project/*"                    # Config files to be included to image (leave empty to disable)
REPLACE_CONFIG_DIR="/src/main/resources/"                       # Config file path destination (leave empty to disable)
IMAGE_PATH="/target/ROOT.war"                                   # Compiled image path
DEPLOY_PATH="/opt/tomcat/webapps/ROOT.war"                      # Tomcat image path to be replaced



#
# Script variables (DO NOT TOUCH!)
#
CURRENT_DIR=$(pwd -P)
TEMP_DIR="${CURRENT_DIR}/.tmp"
CLONED_DIR="${TEMP_DIR}/"
LOG_FILE="${CURRENT_DIR}/deploy.log"

RESET=`echo "\033[m"`
DARK_RED=`echo "\033[0;31m"`
DARK_GREEN=`echo "\033[0;32m"`
DARK_YELLOW=`echo "\033[0;33m"`
RED=`echo "\033[1;91m"`
GREEN=`echo "\033[1;92m"`
YELLOW=`echo "\033[1;93m"`
WHITE=`echo "\033[1;97m"`



# Show splash
function show_splash() {
	clear
	printf "${DARK_YELLOW}*********************************************************${RESET}\n"
	printf "${DARK_YELLOW}*\t${YELLOW}       Tomcat Auto Deployment v1.0       \t${DARK_YELLOW}*${RESET}\n"
	printf "${DARK_YELLOW}*\t\t\t\t\t\t\t*${RESET}\n"
	printf "${DARK_YELLOW}*\t\t${YELLOW}    Powered by VENTO    \t\t${DARK_YELLOW}*${RESET}\n"
	printf "${DARK_YELLOW}*${YELLOW}  https://github.com/VENTO-off/Tomcat-Auto-Deployment  ${DARK_YELLOW}*${RESET}\n"
	printf "${DARK_YELLOW}*********************************************************${RESET}\n\n"
}

# Write logs to file
function write_log() {
	local timestamp=`date "+%Y-%m-%d %H:%M:%S"`
	local description=$1
	
	echo -e "[$timestamp]: $description" >> $LOG_FILE
}

# Show current task in terminal
function current_task() {
	local description=$1
	
	printf "${WHITE}  $description ${RESET}"
	write_log "$description"
}

# Check for error and print current status in terminal
function check_error() {
	local exit_code=$1
	local success_msg=$2
	local error_msg=$3
	
	if [ $exit_code -eq 0 ]; then
		printf "${DARK_GREEN}[${GREEN} OK ${DARK_GREEN}]${RESET}\n"
		write_log "$success_msg."
	else
		printf "\b${DARK_RED}[${RED} ERROR ${DARK_RED}]${RESET}\n"
		write_log "Error has occurred while $error_msg. See details below:"
		write_log "Stopping script execution!"
		rm -rf $TEMP_DIR
		exit 1
	fi
}

# Create a temporary directory
function create_temp_dir() {
	rm $LOG_FILE &>/dev/null
	current_task "Creating temporary directory...\t\t"
	rm -rf $TEMP_DIR &>/dev/null
	mkdir $TEMP_DIR &>> $LOG_FILE
	check_error $? "Temporary directory has been created" "creating a temporary directory"
}

# Clone git repository
function git_clone() {
	current_task "Cloning git repository...\t\t\t"
	cd $TEMP_DIR &>> $LOG_FILE
	git clone -b $GIT_BRANCH --single-branch $GIT_URL &>> $LOG_FILE
	check_error $? "Repository has been cloned" "cloning git repository"
}

# Replace configuration files
function replace_config() {
	CLONED_DIR+=$(ls -d */ | head -n 1)
	cd $CLONED_DIR &>> $LOG_FILE
	
	if [ ! -z $ORIGINAL_CONFIG_DIR ] && [ ! -z $REPLACE_CONFIG_DIR ]; then
		current_task "Replacing configuration...\t\t\t"
		cp -a $ORIGINAL_CONFIG_DIR $CLONED_DIR/$REPLACE_CONFIG_DIR &>> $LOG_FILE
		check_error $? "Configuration has been replaced" "replacing configuration"
	fi
}

# Build image
function build_image() {
	current_task "Building image...\t\t\t\t"
	export JAVA_HOME=$JDK_HOME
	$BUILD_SCRIPT &>> $LOG_FILE
	check_error $? "Image has been created" "building image"
}

# Deploy build to the Tomcat
function deploy_build() {
	current_task "Deploying image...\t\t\t\t"
	mv -f $CLONED_DIR/$IMAGE_PATH $DEPLOY_PATH &>> $LOG_FILE
	check_error $? "Image has been deployed" "deploying image"
}

# Delete temporary files
function clean_up() {
	current_task "Removing temporary files...\t\t\t"
	rm -rf $TEMP_DIR &>/dev/null
	check_error $? "Temporary files have been deleted" "removing temporary files"
}

# run script
show_splash
create_temp_dir
git_clone
replace_config
build_image
deploy_build
clean_up
