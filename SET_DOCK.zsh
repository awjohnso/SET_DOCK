#!/bin/zsh --no-rcs
# set -x

##################################### VARIABLES ##########################################

vers="1.50"
myPID=$$
scriptName=$( /usr/bin/basename ${0} )
myTimeStamp()
{
	/bin/date | /usr/bin/awk  '{ printf "%02s %02s %02s %02s\n", $1,$2,$3,$4 }'
}
Numb_Arguments=$#
argument_1="${1}"
myHost=$( /usr/sbin/scutil --get ComputerName )
myUserShortName=$( /usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' )
myID=$( /usr/bin/id -u ${myUserShortName} )
dockutil="/usr/local/bin/dockutil"
myHome=$( /usr/bin/dscl . read Users/${myUserShortName} NFSHomeDirectory | /usr/bin/awk '{print $2}' )
myLog="${myHome}/Library/Logs/.$(/usr/bin/basename ${scriptName} | /usr/bin/cut -d "." -f 1 ).log"
dockPlist="/Library/Managed Preferences/edu.stonybrook.doit.docksettings.plist"
localAdminAcct="desktopsupport"
URL="https://api.github.com/repos/kcrawford/dockutil/releases/latest"


##################################### FUNCTIONS ##########################################

function logging()
{
    /bin/echo "$(myTimeStamp) ${myHost} ${scriptName}[${myPID}]: ${1}" | /usr/bin/tee -a "${myLog}"
}
function START_SCRIPT()
{
	/bin/echo "" | /usr/bin/tee -a "${myLog}"
	logging "Starting ${scriptName}, Version: ${vers}."
}
function EXIT_SCRIPT()
{
	logging "Ending ${scriptName}, Version: ${vers}."
	/bin/echo "" | /usr/bin/tee -a "${myLog}"
	exit 0
}
function MAKE_TEMP_DIR()
{
	logging "MAKE_TEMP_DIR: Starting MAKE_TEMP_DIR."
		# Make a temp directory to store downloaded files and such.
	myTmpDir=$( /usr/bin/mktemp -d )
	logging "MAKE_TEMP_DIR: Making temp directory: ${myTmpDir}"
	logging "MAKE_TEMP_DIR: Ending MAKE_TEMP_DIR."
}
function REMOVE_TEMP_DIR()
{
	logging "REMOVE_TEMP_DIR: Starting REMOVE_TEMP_DIR."
	logging "REMOVE_TEMP_DIR: Removing temp directory: ${myTmpDir}"
	/bin/rm -Rf "${myTmpDir}"
	logging "REMOVE_TEMP_DIR: Ending REMOVE_TEMP_DIR."
}
function DOWNLOAD_INSTALL_FROM_GITHUB()
{
	MAKE_TEMP_DIR
	DOWNLOAD_URL=$( /usr/bin/curl --silent --url "${URL}" | /usr/bin/plutil -extract assets.0.browser_download_url raw -  )
	logging "DOWNLOAD_INSTALL_FROM_GITHUB: Installing from ${DOWNLOAD_URL}"
	/usr/bin/curl --silent --location --url "${DOWNLOAD_URL}" --output "${myTmpDir}/package.pkg"
	/usr/sbin/installer -pkg "${myTmpDir}/package.pkg" -target / -verbose
	/bin/rm -Rfv "${myTmpDir}/package.pkg"
	REMOVE_TEMP_DIR
}
function SET_DOCK()
{
	local funcName=$( /usr/bin/basename ${0} )
	if [ ! -e ${dockutil} ]; then
		logging "docutil not found."
		logging "Installing from GitHub..."
		DOWNLOAD_INSTALL_FROM_GITHUB
	else
		logging "docutil has been found." | /usr/bin/tee -a "${myLog}"	
		"${dockutil}" --remove all --no-restart "${myHome}"
		
		if [[ "${myUserShortName}" == "${localAdminAcct}" ]]; then
			logging "Setting the Dock for ${myUserShortName}."
			unset count
			local count=$( /usr/bin/plutil -extract "adminDock" raw -o - "${dockPlist}" )
			(( count-- ))
			unset i
			for ((i=0; i<=${count}; i++)); do
				myResult=$( "${dockutil}" --add "$( /usr/bin/plutil -extract "adminDock.${i}" raw -o - "${dockPlist}" )" --no-restart "${myHome}" )
				logging "dockutil: ${myResult}"
				unset myResult
			done
		else
			logging "Setting the Dock for ${myUserShortName}."
			unset count
			local count=$( /usr/bin/plutil -extract "userDock" raw -o - "${dockPlist}" )
			(( count-- ))
			unset i
			for ((i=0; i<=${count}; i++)); do
				myResult=$( "${dockutil}" --add "$( /usr/bin/plutil -extract "userDock.${i}" raw -o - "${dockPlist}" )" --no-restart "${myHome}" )
				logging "dockutil: ${myResult}"
				unset myResult
			done
		fi
		
		unset count
		local count=$( /usr/bin/plutil -extract "Documents" raw -o - "${dockPlist}" )
		(( count-- ))
		unset i
		for ((i=0; i<=${count}; i++)); do
			myResult=$( "${dockutil}" --add "$( /usr/bin/plutil -extract "Documents.${i}" raw -o - "${dockPlist}" )" "${myHome}" )
			logging "dockutil: ${myResult}"
			unset myResult
		done
	fi
}
function MY_VERSION()
{
	if [[ "$1" -eq 1 ]]; then
		case $2 in
			(-v|--version)
				/bin/echo "${vers}"
				exit 0
				;;
			(*)
				exit 0
				;;
		esac
	fi
}
function CHECK_FOR_PLIST()
{
if [ ! -e "${dockPlist}" ]; then
	logging "dockutil: Can not find the plist file with the configuration settings."
	exit 1
fi
}

##################################### MAIN ##########################################

MY_VERSION ${Numb_Arguments} ${argument_1}
CHECK_FOR_PLIST
START_SCRIPT
SET_DOCK
EXIT_SCRIPT
