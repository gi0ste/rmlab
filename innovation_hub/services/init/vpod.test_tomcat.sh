#!/usr/bin/env bash
exec > >(tee -a /var/tmp/init_waitfortomcatready_$$.log) 2>&1
. /usr/local/osmosix/etc/.osmosix.sh
. /usr/local/osmosix/etc/userenv
. /usr/local/osmosix/service/utils/agent_util.sh


URL="http://${cliqrNodePrivateIp}/"
sRetries=3
sTimeout=180
sService=tomcat7

[ ! -z "$1" ] && URL=$1
[ ! -z "$2" ] && sRetries=$2
[ ! -z "$3" ] && sTimeout=$3
[ ! -z "$4" ] && sService=$4

cmdRestartService="service $sService restart > /dev/null 2>&1"


# ==== Check for IPTables Port Redirection and amend 'URL' variable accordingly
URL=${URL,,}
URLproto=$(echo $URL | cut -d':' -f1)
URLport=$(echo $URL | sed "s|.*://||" | grep -P -o ":.*?/" | tr -d ':' | tr -d '/')

[ -z "$URLport" ] && [ "$URLproto" == "http" ] && URLport=80;
[ -z "$URLport" ] && [ "$URLproto" == "https" ] && URLport=443;
[ -z "$URLport" ] && echo "ERROR: Unable to reliably determine URL Port to connect to" && exit 1

#Check IPTables for potential port redirections
natRdrPort=$(sudo iptables -t nat -L -n | grep "REDIRECT" | grep "dpt:${URLport}" | awk '{print $NF}')
#Keep the first value if multiple redirections found
natRdrPort=$(echo $natRdrPort | cut -d' ' -f1)

if [ ! -z "$natRdrPort" ] && [ "$URLport" -ne "$natRdrPort" ]; then
  if echo $URL | egrep -q ":${URLport}/"; then
     URL=$(echo $URL | sed "s|:${URLport}/|:${natRdrPort}|")
   else
     tmpURI=$(echo $URL | grep -P -o "://.*?/")
     tmpURI2=$(echo $tmpURI | sed "s|/$|:${natRdrPort}/|")
     URL=$(echo $URL | sed "s|$tmpURI|$tmpURI2|")
  fi
  echo IPTables Port Redirection found. Redirecting port $URLport to $natRdrPort
fi
# ========


echo "Testing URL '$URL' (Timeout: $sTimeout, Retries: $sRetries, Service: $sService)"
agentSendLogMessage "TestTomcat: Waiting for Tomcat server ready" > /dev/null

iRetries=$sRetries
iTimeout=$sTimeout
fRestartService=false
while [ $iRetries -ge 0 ]; do

  $fRestartService && fRestartService=false && $cmdRestartService

  sleep 1
  echo -n "Making HTTP Web Request ... "
  tBEFORE=$(cat /proc/uptime | cut -d' ' -f1 | cut -d'.' -f1)
  RET=($(curl -s -I -m $sTimeout $URL 2> /dev/null)); STATUS=$?
  tAFTER=$(cat /proc/uptime | cut -d' ' -f1 | cut -d'.' -f1)
  tTOTAL=$(expr $tAFTER - $tBEFORE)

  ## STATUS contains OS error codes
  ## ${RET[1]} represents HTTP Response codes when a call was successful

  case $STATUS in
     0) case ${RET[1]} in
          200) echo "SUCCESS: Server is ready! (${tTOTAL} sec)"
               agentSendLogMessage "TestTomcat: Success. Server is ready" > /dev/null
               exit 0
               ;;
          404) echo "FAILED: Page not found, restarting"
               fRestartService=true
               ;;
            *) echo "FAILED: Unexpected HTTP Return Code (${RET[1]})"
               agentSendLogMessage "TestTomcat: FAILED. HTTP Status returned: ${RET[1]}" > /dev/null
               exit 1
               ;;
        esac
        ;;
     7) echo "FAILED: Connection refused, retrying ($iTimeout)"
        ((iTimeout--))
        ;;
    28) echo "FAILED: Connection timeout after $sTimeout sec, restarting."
        fRestartService=true
        ;;
     *) echo "FAILED: Unknown error code ($STATUS)"
        agentSendLogMessage "TestTomcat: FAILED. Return error code: $STATUS" > /dev/null
        exit 1
        ;;
  esac

  [ $STATUS -ne 7 ] && iTimeout=$sTimeout

  [ $iTimeout -eq 0 ] && iTimeout=$sTimeout && fRestartService=true

  $fRestartService && ((iRetries--))

done

echo "ERROR: Server not ready"
agentSendLogMessage "TestTomcat: FAILED. Server did not become ready" > /dev/null

exit 1
