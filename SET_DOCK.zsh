#!/bin/zsh --no-rcs
# set -x

##################################### VARIABLES ##########################################

myPID=$$
myProcName=$( /usr/bin/basename ${0} )
myTimeStamp()
{
	/bin/date | /usr/bin/awk  '{ printf "%02s %02s %02s %02s\n", $1,$2,$3,$4 }'
}
myHost=$( /usr/sbin/scutil --get ComputerName )
vers="1.00"
myUserShortName=$( /usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' )
myID=$( /usr/bin/id -u ${myUserShortName} )
dockutil="/usr/local/bin/dockutil"
myHome=$( /usr/bin/dscl . read Users/${myUserShortName} NFSHomeDirectory | /usr/bin/awk '{print $2}' )
myLog="${myHome}/Library/Logs/.$(/usr/bin/basename ${myProcName} | /usr/bin/cut -d "." -f 1 ).log"
dockPlist="/Library/Managed Preferences/edu.stonybrook.doit.docksettings.plist"
localAdminAcct="desktopsupport"
URL="https://api.github.com/repos/kcrawford/dockutil/releases/latest"


##################################### FUNCTIONS ##########################################

function MAKE_TEMP_DIR()
{
		# Make a temp directory to store downloaded files and such.
	myTmpDir=$( /usr/bin/mktemp -d )
	/bin/echo "$(myTimeStamp) ${myHost} ${scriptName}[${myPID}]: MAKE_TEMP_DIR: Making temp directory : ${myTmpDir}" | /usr/bin/tee -a "${myLog}"
}
function REMOVE_TEMP_DIR()
{
		# Remove the temp directory.
	/bin/echo "$(myTimeStamp) ${myHost} ${scriptName}[${myPID}]: REMOVE_TEMP_DIR: Removing temp directory: ${myTmpDir}" | /usr/bin/tee -a "${myLog}"
	/bin/rm -Rf "${myTmpDir}"
}
function DOWNLOAD_INSTALL_FROM_GITHUB()
{
	MAKE_TEMP_DIR
	DOWNLOAD_URL=$( /usr/bin/curl --silent --url "${URL}" | /usr/bin/plutil -extract assets.0.browser_download_url raw -  )
	/bin/echo "$(myTimeStamp) ${myHost} ${scriptName}[${myPID}]: DOWNLOAD_INSTALL_FROM_GITHUB: Installing from ${DOWNLOAD_URL}" | /usr/bin/tee -a "${myLog}"
	/usr/bin/curl --silent --location --url "${DOWNLOAD_URL}" --output "${myTmpDir}/package.pkg"
	/usr/sbin/installer -pkg "${myTmpDir}/package.pkg" -target / -verbose
	/bin/rm -Rfv "${myTmpDir}/package.pkg"
	REMOVE_TEMP_DIR
}
function SET_DOCK()
{
	local funcName=$( /usr/bin/basename ${0} )
	if [ ! -e ${dockutil} ]; then
		/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}:${funcName}[${myPID}]: !! docutil not found !!" | /usr/bin/tee -a "${myLog}"
		/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}:${funcName}[${myPID}]: !! Installing from GitHub..." | /usr/bin/tee -a "${myLog}"
		DOWNLOAD_INSTALL_FROM_GITHUB
	else
		/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}:${funcName}[${myPID}]: docutil has been found." | /usr/bin/tee -a "${myLog}"	
		"${dockutil}" --remove all --no-restart "${myHome}"
		
		if [[ "${myUserShortName}" == "${localAdminAcct}" ]]; then
			/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}:${funcName}[${myPID}]: Setting the Dock for ${myUserShortName}." | /usr/bin/tee -a "${myLog}"
			unset count
			local count=$( /usr/bin/plutil -extract "adminDock" raw -o - "${dockPlist}" )
			(( count-- ))
			unset i
			for ((i=0; i<=${count}; i++)); do
				myResult=$( "${dockutil}" --add "$( /usr/bin/plutil -extract "adminDock.${i}" raw -o - "${dockPlist}" )" --no-restart "${myHome}" )
				/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}:${funcName}[${myPID}]: dockutil: ${myResult}" | /usr/bin/tee -a "${myLog}"
				unset myResult
			done
		else
			/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}:${funcName}[${myPID}]: Setting the Dock for ${myUserShortName}." | /usr/bin/tee -a "${myLog}"
			unset count
			local count=$( /usr/bin/plutil -extract "userDock" raw -o - "${dockPlist}" )
			(( count-- ))
			unset i
			for ((i=0; i<=${count}; i++)); do
				myResult=$( "${dockutil}" --add "$( /usr/bin/plutil -extract "userDock.${i}" raw -o - "${dockPlist}" )" --no-restart "${myHome}" )
				/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}:${funcName}[${myPID}]: dockutil: ${myResult}" | /usr/bin/tee -a "${myLog}"
				unset myResult
			done
		fi
		
		unset count
		local count=$( /usr/bin/plutil -extract "Documents" raw -o - "${dockPlist}" )
		(( count-- ))
		unset i
		for ((i=0; i<=${count}; i++)); do
			myResult=$( "${dockutil}" --add "$( /usr/bin/plutil -extract "Documents.${i}" raw -o - "${dockPlist}" )" "${myHome}" )
			/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}:${funcName}[${myPID}]: dockutil: ${myResult}" | /usr/bin/tee -a "${myLog}"
			unset myResult
		done
	fi
}

##################################### MAIN ##########################################

/bin/echo "" | /usr/bin/tee -a "${myLog}"
/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: Starting ${myProcName}. Version: ${vers}." | /usr/bin/tee -a "${myLog}"

if [ -e "${dockPlist}" ]; then
	SET_DOCK
else
	/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: Can not find the plist file with the configuration settings." | /usr/bin/tee -a "${myLog}"
fi

/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: Ending: ${myProcName}. Version: ${vers}." | /usr/bin/tee -a "${myLog}"
/bin/echo "" | /usr/bin/tee -a "${myLog}"

exit 0
