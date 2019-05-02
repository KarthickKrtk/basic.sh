#!/bin/sh

SCRIPT_VERSION="17.2.3"
SCRIPT_NAME=${0}


setTime() {

	# set time
	NOW="`date '+%m/%d/%Y %H:%M %Z'`"

}

echo_print() {
  eval 'printf "%b\n" "$*"'
} 


setOutputFiles() {



	FILE_EXT=${$}

	# set tmp directory and files we will use in the script
	TMPDIR="${TMPDIR:-/tmp}"
	ORA_IPADDR_FILE=$TMPDIR/oraipaddrs.$FILE_EXT
	ORA_MSG_FILE=$TMPDIR/oramsgfile.$FILE_EXT
	touch ${ORA_MSG_FILE}

	# this wil allow us to pass the ORA_MACHINE_INFO file name 
	# from a calling shell script
	ORA_MACHINFO_FILE=${1:-${TMPDIR}/${MACHINE_NAME}-lms_cpuq.txt} 

	ORA_PROCESSOR_FILE=$TMPDIR/$MACHINE_NAME-proc.txt

	# debug and error files
	ORA_DEBUG_FILE=$TMPDIR/oradebugfile.$FILE_EXT
	UNIXCMDERR=${TMPDIR}/unixcmderrs.$FILE_EXT

	
	$ECHO_DEBUG "\ndebug.function.setOutputFiles"
}

beginMsg()
{
$ECHO   "Terms for Oracle License Management Services (\"LMS\") Software

Last updated 21 December 2015
\n" | more


ANSWER=

$ECHO "Accept License Agreement? "
	while [ -z "${ANSWER}" ]
	do
		$ECHO "$1 [y/n/q]: \c" >&2
  	read ANSWER
		#
		# Act according to the user's response.
		#
		case "${ANSWER}" in
			Y|y)
				return 0     # TRUE
				;;
			N|n|Q|q)
				exit 1     # FALSE
				;;
			#
			# An invalid choice was entered, reprompt.
			#
			*) ANSWER=
				;;
		esac
	done
}


printMachineInfo() {
	
	NUMIPADDR=0
	
	# print script information
	$ECHO "[BEGIN SCRIPT INFO]"
	$ECHO "Script Name=$SCRIPT_NAME"
	$ECHO "Script Version=$SCRIPT_VERSION"
	$ECHO "Script Command options=$SCRIPT_OPTIONS"
	$ECHO "Script Command shell=$SCRIPT_SHELL"
	$ECHO "Script Command user=$SCRIPT_USER"
	$ECHO "Script Start Time=$NOW"
	# Get the approximate end time of the script by calling setTime again.
	setTime
	$ECHO "Script End Time=$NOW"
	$ECHO "[END SCRIPT INFO]"

	# print system information
	$ECHO "[BEGIN SYSTEM INFO]"
	$ECHO "Machine Name=$MACHINE_NAME"
	$ECHO "Operating System Name=$OS_NAME"
	$ECHO "Operating System Release=$RELEASE"

	for IP in `cat $ORA_IPADDR_FILE`
	do
		NUMIPADDR=`expr ${NUMIPADDR} + 1`
		$ECHO "System IP Address $NUMIPADDR=$IP"
	done
	
	cat ${ORA_PROCESSOR_FILE}
	cksum ${ORA_MSG_FILE} | cut -d' ' -f1-2

	$ECHO "[END SYSTEM INFO]"

	}

CredentialValidation() {
if [ $OS_NAME = "Linux" ] && [ $USR_ID != "root" ] ; then
		$ECHO "Current OS user $USR_ID does NOT have administrative rights!"
		$ECHO "If you are sure that the Current OS user $USR_ID is granted the required privileges, continue with yes(y), otherwise select No(n) and please log on with a OS user with sufficient privileges."
		$ECHO "Running Processor Queries with insufficient privileges may have a significant impact on the quality of the data and information collected from this environment. Due to this, Oracle LMS may have to get back to you and ask for additional items, or to execute again."
        ANSWER=
     while [ -z "${ANSWER}" ]
	 do
		$ECHO "Do you wish to continue anyway? [y/n]: \c" >&2
	   	read ANSWER
		case "${ANSWER}" in
			Y|y)
				return 0     # TRUE
				;;
			N|n)
				exit 1     # FALSE
				;;
			*) ANSWER=
				;;
		esac
 	done 		
	
 fi
}

umask 022

SCRIPT_OPTIONS=${*}
LOG_FILE="true"


OS_NAME=`uname -s`
MACHINE_NAME=`uname -n`

USER_ID_CMD=`type whoami >/dev/null 2>/dev/null && echo "Found" || echo "NotFound"`
if [ "$USER_ID_CMD" = "Found" ] ; then
	USR_ID=`whoami`
else
	if [ "$OS_NAME" = "SunOS" ] ; then
		if [ -x /usr/ucb/whoami ] ; then
			USR_ID=`/usr/ucb/whoami`
		fi
	else
		USR_ID=$LOGNAME
	fi
fi

if [ "$USR_ID" = "root" ] ; then
	SCRIPT_USER="ROOT"
else
	SCRIPT_USER=$USR_ID
fi

# set up $ECHO
ECHO="echo_print"


# search start time
setTime
SEARCH_START=$NOW
$ECHO "\nScript started at $SEARCH_START" 

ps -eaf | grep waagent | grep -v grep >/dev/null 2>&1
if [ $? -eq 0 ] ; then
        waagent="false"
else
       
              waagent="true"
       
fi

if [ "${waagent}" = "true" ] ; then

        # print welcome message
        beginMsg
		CredentialValidation
fi


# set output files
setOutputFiles ${1}



# Write machine info to the output file
printMachineInfo > $ORA_MACHINFO_FILE 2>>$UNIXCMDERR

if [ -s $UNIXCMDERR ];
then
	cat $UNIXCMDERR >> $ORA_MACHINFO_FILE
fi

# search finish time
setTime
SEARCH_FINISH=$NOW

# if "${STANDALONE}" = "true" then we did not get called from LMSCollection.sh   
# so we need to print the following
if [ "${waagent}" = "true" ] ; then
	$ECHO "\nScript $SCRIPT_NAME finished at $SEARCH_FINISH"
	$ECHO "\nPlease collect the output file generated: $ORA_MACHINFO_FILE"
fi


# delete the tmp files
rm -rf $ORA_IPADDR_FILE $ORA_DEBUG_FILE $ORA_PROCESSOR_FILE $ORA_MSG_FILE $UNIXCMDERR 2>/dev/null

exit 0
