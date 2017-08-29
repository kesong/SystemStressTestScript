#!/bin/bash

#############################################################################################################################################################
# Purpose:
#	
#	This script is do some pressure test on spreadtrum smart phone which running android system. 
#	It's mainly do 4 kinds of operation, they are playing music, take photos, install applications and running monkey test.
#	But we can decide how long or how many times each test mentioned above we want it to run.
#
# Test procedure:
#
#	The script will running as following steps:
#
#	First, it will launch music and play mp3 stored in TF card, then start monkey test in fore ground, and make music playing  
#	continuely in back ground. How long will it running defined by the parameter we passed to the script.
#	Secondly, it will launch camera and take photo many times, the times is defined by tester too.
#	Thirdly, it will found if there is application available to install under the directory specified.
#
# Condfiguriton:
#
#	We have to specified the package name and activity name of music and camera, which were specified as:
#
#	Music="xxx.xxx.xxx/xxx.xxx.xxx"					# activity name of music
#	MusicPac"xxx.xxx.xxx"							# package name of music
#
#	Camera="xxx.xxx.xxx"							# activity name of camera
#	CameraPac="xxx.xxx.xxx"							# package name of camera
#
# Options:
#
#	-c			times of take photos, 100 by default if not specified.
#	-t			count of timer will run, for instance, xx -t 20, the timer will be 20*600=12000 seconds, 600 seconds by default if  not specified
#	-R			rounds of mp4 video will be played
#	-s			specify the device which you want to run test
#	-r			rounds of all tests(mp3 playing, monkey test, camera take photoes, apk install, mp4 playing) running
#	-h			usage of script
#	-v			version of script
#
# Usage:
#
#	The usage of script is like this:
#
#	./ContinuousPressTest.sh -c 20 -t 10 -R 10
#
# Author:
#	FAE TEST GROUP(spreadtrum CO.LTD)
#	song.ke@spreadtrum.com
#
############################################################################################################################################################
#
# Package and activity of monkey
monkeyPac="com.android.commands.monkey"
#
# File name of configuration 
fileName="PackageAndActivity.cfg"
#
# Counts of photoes will be taken 
CameraCount=100
TimerCount=1
#
# Make a connection between phone and local PC via adb
ADB="/sbin/adbd"
#
# The default value of rounds the video will be played, the path of mp4 stored
PlayRounds=5
#mp4Path="/storage/sdcard0/mp4video"
#
# Device number by default
deviceNo=""
#
# Rounds of all test running
looptime=1
#
# Version of the script
version=1.0.1
############################################################################################################################################################

# Help of the usage
function help
{
	echo "USAGE:"
	echo "$0 [-c count] [-t count] [-R round] [-s] [device] [-r loop times]"
	echo "			-c  tiems of take photos, 100 by default if not specified"
	echo "			-t  count of timer will run, 600 seconds by default if not specified"
	echo "			-s  specify the devcies number if you have more than one devices connected"
	echo "			-R  rounds of mp4 will be played, 5 rounds by default if not specified"
	echo "			-r  rounds of all tests(mp3 playing, monkey test, camera test, apk install and mp4 playing) will be running"
	echo "			-h  help, usage introduction."
	echo "			-v  version of the script."
	echo "Usage Example: "
	echo ""
	echo "$0"
	echo "The timer will be 600 seconds, the number of photos will be taken is 100, the mp4 will be played 5 rounds"
	echo ""
	echo "$0 -c 20"
	echo "It will take photo 20 times."
	echo ""
	echo "$0 -t 10"
	echo "The timer will be 10*600=6000 seconds, the monkey will running 6000 seconds."
	echo ""
	echo "$0 -R 4"
	echo "The rounds will be 4, it means the mp4 video in the specified path will be played in the order," 
	echo "and after it will start from the first one when the last one played finished," 
	echo "the whole play action will be repeated 4 times."
	echo ""
	exit 1
}

# Get arguments from commandline and resolve it
while getopts :c:t:R:s:r:hv opt
do
	case "$opt" in
		c)	CameraCount="$OPTARG"	
			echo "The number of camera will run is "$CameraCount""	
			;;
		t)	TimerCount="$OPTARG"	
			echo "The number of timer will run is "$TimerCount""	
			;;
		R)	PlayRounds="$OPTARG"
			echo "The rounds of video playing is "$PlayRounds""
			;;
		s)	deviceNo="-s $OPTARG"
			;;
		r)	looptime="$OPTARG"
			;;
		v)	echo "The version of script is $version"
			exit 1
			;;
		h)	help
			exit 1
			;;
		:)	echo "Shall supply an argument to -$OPTARG." >&2
			help
			exit 1
			;;
		?)	echo "Ivalid option -$OPTARG." >&2
			help
			exit 1
			;;
	esac
done

# Read acvitity and package name of music and camera from file
function getPackageName
{
	if [ -f "$fileName" ]; then
		Music=`cat "$fileName" | grep -w "MusicAct" | cut -d '=' -f 2`
		MusicPac=`cat "$fileName" | grep -w "MusicPac" | cut -d '=' -f 2`
		Camera=`cat "$fileName" | grep -w "CameraAct" | cut -d '=' -f 2`
		CameraPac=`cat "$fileName" | grep -w "CameraPac" | cut -d '=' -f 2`
		apkPath=`cat "$fileName" | grep -w "apkPath" | cut -d '=' -f 2`
	else
		echo "The "$fileName" is not exist, please check or you can create a new."
		echo ""
		exit 1
	fi
	return 0
}

# Launch an app
function RunningApp 
{
	if [ $# -ne 2 ]; then
		echo "There is an error occured when start an application."
		echo "You should provide 2 arguments, the name of activity and name of package."
		echo "Usage: RunningApp ActivityName PackageName"
		echo ""
		return 1
	fi
	adb $deviceNo shell input keyevent KEYCODE_HOME
	adb $deviceNo shell input keyevent KEYCODE_HOME
	sleep 2
    # The "$1" is the activity name, the "$2" is the package name.
	echo "Start $2"
	echo ""
	while [ 1 -gt 0 ]
	do
		adb $deviceNo shell am start -S "$1"
		AppProcess=`adb shell ps | grep -w "$2" | awk '{print $9}' | tr -d '\r'`
		if [ "$AppProcess" = $2 ]; then
			echo "The application is launched successfully!"
			echo ""
			return 0
		fi
	done
}

# Playing music
function PlayMusic 
{
	adb $deviceNo shell input keyevent KEYCODE_HOME
	RunningApp $Music $MusicPac
	sleep 2
	# Play music in the list
	adb $deviceNo shell input keyevent KEYCODE_MEDIA_PLAY
	sleep 5
}

# Take photo continuously
function CameraRun 
{
	adb $deviceNo shell input keyevent KEYCODE_HOME
	RunningApp $Camera $CameraPac
	sleep 2

	i=0
	while (( i < $CameraCount ))
	do
		adb $deviceNo shell input keyevent KEYCODE_CAMERA
		sleep 1
		i=`expr $i + 1`
	done
}

# Running monkey test
function MonkeyTest 
{
	cat "$fileName" | grep -w "MusicPac" | cut -d '=' -f 2 > blacklist
	if [ -f blacklist ]; then
		adb $deviceNo push blacklist /data/local/tmp 2>/dev/null
	else
		echo "The blacklist file is not found, is the file is created in the current direcoty?"
		echo ""
	fi
	monkeyParam="--ignore-crashes --ignore-timeouts --ignore-security-exceptions --pkg-blacklist-file /data/local/tmp/blacklist --ignore-native-crashes --kill-process-after-error --monitor-native-crashes --throttle 500 -v -v -v 200000"
	echo "monkey test starting, log save in current directory!"
	adb $deviceNo shell monkey "$monkeyParam" >> monkey.log &
	sleep 5
	monkeyProc=`adb $deviceNo shell ps | grep -w "$monkeyPac" | awk '{print $9}' | tr -d '\r'`
	if [ "$monkeyProc" = $monkeyPac ]; then
		echo "The monkey test is start."
		echo ""
	else
		echo "The monkey test start failed, please verify the adb connection or the status of the phone."
		echo ""
		return 1
	fi
	# Change priority of process monkey
	monkeyPid=`adb $deviceNo shell ps | grep -w "$monkeyPac" | awk '{print $2}'`
	echo "The monkey is running, the monkey ID is $monkeyPid."
	echo ""
	adb $deviceNo shell echo -16 > /proc/$monkeyPid/oom_adj
	adb $deviceNo shell cat /proc/$monkeyPid/oom_adj
	sleep 2
}

# A timer for 1 hour.
function timer_10m 
{
	timer=$[$TimerCount * 600]
	startTime=`date "+%H:%M:%S %d/%m/%Y"`
	echo "Timer start at "$startTime", it will be a long boring time to waiting for the timer ending, so go and have a chat with a pretty girl."
	echo ""
	sleep $timer
	endTime=`date "+%H:%M:%S %d/%m/%Y"`
	echo "Timer end at "$endTime", the next step will start in several seconds."
	echo ""
	return 0
}

# Kill monkey process 
function KillMonkey 
{
	echo "We have to kill the monkey process, then start another kind of test."
	echo ""
	monkeyProcess=`adb $deviceNo shell ps | grep -w "$monkeyPac" | awk '{print $2}'`
	if [ -n $monkeyProcess ]; then
		adb $deviceNo shell kill -9 $monkeyProcess
	fi
}

# Install application
function InstallApp
{
	if [ -d "$apkPath" ]; then
		if [ -z `ls "$apkPath"` ]; then
			echo "There is no apk in the directory, you may want to add some apk in the directory."
			echo ""
			return 0
		else
			for package in `ls "$apkPath"`
			do
				adb $deviceNo install "$apkPath/$package" > apkInstall 
				InstallResult=`cat apkInstall | tail -n 1 | tr -d '\r'`
				if [ "$InstallResult" != "Success" ]; then
					echo "The application "$package" install failed, check the log of installation may give you more details."
					echo ""
				else
					echo "Congratulations! The apk "$package" install successfully!"
					echo ""
				fi
			done
		fi
	rm apkInstall
	else
		echo "The directory is not exist, you will need to create a directory or modify the configure file to make the apkPath is an exist directory."
		echo ""
		return 1
	fi

	sleep 5
}

# Playing mp4 video in the specified path
function Mp4Play
{
	local video
	local round
	round=0
	Tcard=`adb $deviceNo shell df | grep "/storage/sdcard" | awk '{print $1}'`
	if [ -z "$Tcard" ]; then
		echo "No T card found in the phone, are you sure you insert a TF card?"
		exit 1
	else
		videoPath=`adb shell ls $Tcard | grep "mp4video" | tr -d '\r'`
		if [ -z "$videoPath" ]; then
			echo "There is no directory named 'mp4video' in the T card. Do you forget to create the directory?"
			exit 1
		else
			mp4Path=$Tcard/$videoPath
			if [ -z "$mp4Path" ]; then
				echo "The video path is not exist. Please check the directory and video path again, Baby."
				exit 1
			fi
		fi
	fi

	adb $deviceNo shell ls $mp4Path > videolist

	if [ -f videolist ]; then
		video=(`cat videolist | tr -s '\r\n' ' '`)
	else
		echo "The file 'videolist' is not exist, You should check if there is mp4 video in the specified path"
		exit 1
	fi

	count=`adb $deviceNo shell ls $mp4Path | wc -l`
	if [ $count -eq 0 ]; then
		echo "There is no video found in the fixed path of T card."
		echo "\n"
		exit 1
	fi

	while [ $round -le $PlayRounds ]
	do
		for((i=0; i<$count; i++))
		do
			adb $deviceNo shell input keyevent KEYCODE_HOME
			adb $deviceNo shell am start -n com.android.gallery3d/.app.MovieActivity -d file://$mp4Path/${video[$i]}
			sleep 4m
			adb $deviceNo shell input keyevent KEYCODE_BACK
			adb $deviceNo shell input keyevent KEYCODE_BACK
			adb $deviceNo shell input keyevent KEYCODE_BACK
			adb $deviceNo shell input keyevent KEYCODE_HOME
		done
		round=`expr $round + 1`
	done
	rm videolist
	return 0
}

if [ $? -eq 1 ]; then
	echo "There is somethin wrong with your arguments, check the notification or you can input -h to get more help."
	exit 1
fi
# Check if the phone connect to the local PC right.
function LoopTest
{
	ADBStatus=`adb $deviceNo shell ps | grep $ADB | awk '{print $9}' | tr -d '\r'`
	SerialNo=`adb get-serialno`
	echo "Check the status of the connection of adb."
	echo ""
	if [ -z "$SerialNo" ] || [ -z "$ADBStatus" ]; then
		echo "The phone and local PC haven't connected, please check if the adb is start right."
		echo ""
		sudo adb kill-server
		sudo adb start-server
		sudo adb devices
	fi

	sleep 2

	getPackageName

	sleep 2

	# Starting Test
	if [ -n "$ADBStatus" ]; then
		PlayMusic
		MonkeyTest
		echo "Music and monkey testing start now! Make the phone bright during the test."
		echo ""
	else
		echo "There is no devices connected, please check the status of adb connection."
		echo ""
	fi

	# Testing will running about 1 hour, the timer is started
	timer_10m
	sleep 5

	# Kill monkey after monkey test running 1 hour
	KillMonkey
	sleep 2

	if [ -n "$ADBStatus" ]; then
	CameraRun
		echo "Camera testing start now, please keep the phone bright during camera test."
		echo ""
	else
		echo "There is no device found, please check the status of adb connection."
		echo ""
	fi

	sleep 5

	# Play video stored in the T card, put the video in the path /storage/sdcard/mp4video.
	if [ -n "$ADBStatus" ]; then
		Mp4Play
	else
		echo "There is no device found, please check  the status of adb connection."
		echo ""
	fi
	
	sleep 5

	# Start install application
	if [ -n "$ADBStatus" ]; then
	InstallApp
		echo "blah"
	else
		echo "There is no device found, please check the status of adb connection."
		echo ""
	fi
}

if [ $? -eq 1 ]; then
	echo "There is somethin wrong with your arguments, check the notification or you can input -h to get more help."
	exit 1
else
	for ((i=0; i<=$looptime; i++))
	do
		LoopTest
	done
fi
