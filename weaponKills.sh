#!/bin/bash

clear

########################################
####  the100.io Weapon Kills v2.5   ####
#### Scrapes member list from group ####
####  Calls Bungie API to get grim  ####
#### 	  the100:  /u/L0r3          ####
####      Reddit:  /u/L0r3_Titan    ####
####      Twitter: @L0r3_Titan      ####
########################################

#### WEAPON ARRAY ####
grimCard="\
304010,RocketLauncher \
304040,MachineGun \
303200,Sidearm \
303010,Shotgun \
303040,FusionRifle \
303070,SniperRifle \
302010,AutoRifle \
302050,ScoutRifle \
302070,PulseRifle \
302090,HandCannon"

#### READ grimCard INTO ARRAY VARIABLE, COUNT # OF OBJECTS IN ARRAY, PICK RANDOM ####
IFS=' '
grimObject=($grimCard)
grimCardCount=${#grimObject[*]}
currentCard=`echo ${grimObject[$((RANDOM%grimCardCount))]}`

#### MANUAL OVERRIDE IF YOU WANT TO PROCESS SPECIFIC ENEMY ####
currentCard='303070,SniperRifle'

#### INCLUDE FILE WITH YOUR BUNGIE API KEY ####
source ${BASH_SOURCE[0]/%weaponKills.sh/apiKey.sh}
source ${BASH_SOURCE[0]/%weaponKills.sh/hundredMembers.sh}

#### SEPRATE GRIM CARD ID AND NAME ####
grimID=`echo $currentCard | sed 's/,.*[^,]*//'`
grimName=`echo $currentCard | rev | sed 's/,.*[^,]*//' | rev`

#### CALL FUNCTION TO SCRAPE THE100 MEMBERS ####
hundredMembers

#### XBOX OR PSN ####
selectedAccountType='1'

#### SOURCE OF USERS TO PROCESS (this is produced by scraper) ####
playerList="/tmp/100_usersClean.txt"

#### FUNCTION TO SEND USERNAME TO BUNGIE TO GET MEMBER ID ####
funcMemID ()
{
sleep 1
getUser=`curl -s -X GET \
-H "Content-Type: application/json" -H "Accept: application/xml" -H "$authKey" \
"http://www.bungie.net/Platform/Destiny/SearchDestinyPlayer/$selectedAccountType/$player/"`
memID=`echo "$getUser" | grep -o 'membershipId.*' | cut -c 16- | sed 's/displayName.*[^displayName]*//' | rev | cut -c 4- | rev`
}

#### FUNCTION TO GET ALL THE DATA FROM A SPECIFIC GRIM CARD ("statNumber":1)  ####
funcGetGrimData ()
{
sleep 1
grimMinion=`curl -s -X GET \
-H "Content-Type: application/json" -H "Accept: application/xml" -H "$authKey" \
"https://www.bungie.net/Platform/Destiny/Vanguard/Grimoire/1/$memID/?single=$grimID"`
grimStatOne=`echo "$grimMinion" | grep -o 'statNumber":1.*' | sed 's/displayValue.*[^displayValue]*//' | rev | cut -c 5- | sed 's/eulav.*[^eulav]*//' | rev | cut -c 3-`
}

#### LOOP THOUGH LIST OF MEMBERS, RUN FUNCTIONS TO GET BUNGIE GRIM DATA ####
let groupKills='0'
let playerCnt='0'
while read 'player'; do
	funcMemID
	funcGetGrimData
	let groupKills=groupKills+$grimStatOne
	echo "$player: $grimStatOne $grimName kills (group $the100group: $groupKills)"
	let playerCnt=playerCnt+1
	grimArr[$playerCnt]="$grimStatOne,$player"
done < "$playerList"

#### SORT SCORES HIGHEST TO LOWEST ####
function arrSort 
{ for i in ${grimArr[@]}; do echo "$i"; done | sort -n -r -s ; }
echo
grimScoresSort=( $(arrSort) )
printf '%s\n' "${grimScoresSort[@]}"

echo
echo "Group $the100group: $groupKills $grimName kills"
echo

exit
