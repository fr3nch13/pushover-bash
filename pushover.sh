#!/usr/bin/env bash

set -o nounset

readonly API_URL="https://api.pushover.net/1/messages.json"
readonly API_URL_VALIDATE="https://api.pushover.net/1/users/validate.json"
readonly CONFIG_FILE="pushover-config"
readonly DEFAULT_CONFIG="/etc/pushover/${CONFIG_FILE}"
readonly USER_OVERRIDE=~/.pushover/${CONFIG_FILE}
readonly PROJECT_ROOT_PATH=`realpath .`
readonly USER_OVERRIDE_PROJECT=${PROJECT_ROOT_PATH}/${CONFIG_FILE}
readonly EXPIRE_DEFAULT=180
readonly RETRY_DEFAULT=30
HIDE_REPLY=1
VALIDATE=0
debug=0

showHelp()
{
        local script=`basename "$0"`
        echo "Send Pushover v1.2 scripted by Nathan Martini"
        echo "Push notifications to your Android, iOS, or desktop devices"
        echo
        echo "NOTE: This script requires an account at http://www.pushover.net"
        echo
        echo "usage: ${script} <-t|--token apikey> <-u|--user userkey> <-m|--message message> [options]"
        echo
        echo "  -t,  --token APIKEY        The pushover.net API Key for your application"
        echo "  -u,  --user USERKEY        Your pushover.net user key"
        echo "  -m,  --message MESSAGE     The message to send; supports HTML formatting"
        echo "  -a,  --attachment filename The Picture you want to send"
        echo "  -T,  --title TITLE         Title of the message"
        echo "  -d,  --device NAME         Comma seperated list of devices to receive message"
        echo "  -U,  --url URL             URL to send with message"
        echo "       --url-title URLTITLE  Title of the URL"
        echo "  -H,  --html                Enable HTML formatting, cannot be used with the --monospace flag"
        echo "  -M,  --monospace           Enable monospace messages, cannot be used with the --html flag"
        echo "  -p,  --priority PRIORITY   Priority of the message"
        echo "                               -2 - no notification/alert"
        echo "                               -1 - quiet notification"
        echo "                                0 - normal priority"
        echo "                                1 - bypass the user's quiet hours"
        echo "                                2 - require confirmation from the user"
        echo "  -e,  --expire SECONDS      Set expiration time for notifications with priority 2 (default ${EXPIRE_DEFAULT})"
        echo "  -r,  --retry COUNT         Set retry period for notifications with priority 2 (default ${RETRY_DEFAULT})"
        echo "  -s,  --sound SOUND         Notification sound to play with message"
        echo "                                pushover - Pushover (default)"
        echo "                                bike - Bike"
        echo "                                bugle - Bugle"
        echo "                                cashregister - Cash Register"
        echo "                                classical - Classical"
        echo "                                cosmic - Cosmic"
        echo "                                falling - Falling"
        echo "                                gamelan - Gamelan"
        echo "                                incoming - Incoming"
        echo "                                intermission - Intermission"
        echo "                                magic - Magic"
        echo "                                mechanical - Mechanical"
        echo "                                pianobar - Piano Bar"
        echo "                                siren - Siren"
        echo "                                spacealarm - Space Alarm"
        echo "                                tugboat - Tug Boat"
        echo "                                alien - Alien Alarm (long)"
        echo "                                climb - Climb (long)"
        echo "                                persistent - Persistent (long)"
        echo "                                echo - Pushover Echo (long)"
        echo "                                updown - Up Down (long)"
        echo "                                none - None (silent)"
        echo "  -x,  --validate            If set, it will only validate the account"
        echo "  -v,  --verbose             Return API execution reply to stdout"
        echo "  -D,  --debug               Print out debugging information"
        echo "                                Warning, this will output your user key and token to stdout"
        echo
        echo "EXAMPLES:"
        echo
        echo "  ${script} -t xxxxxxxxxx -u yyyyyyyyyy -m \"This is a test\""
        echo "  Sends a simple \"This is a test\" message to all devices."
        echo
        echo "  ${script} -t xxxxxxxxxx -u yyyyyyyyyy -m \"This is a test\" -T \"Test Title\""
        echo "  Sends a simple \"This is a test\" message with the title \"Test Title\" to all devices."
        echo
        echo "  ${script} -t xxxxxxxxxx -u yyyyyyyyyy -m \"This is a test\" -d \"Phone,Home Desktop\""
        echo "  Sends a simple \"This is a test\" message to the devices named \"Phone\" and \"Home Desktop\"."
        echo
        echo "  ${script} -t xxxxxxxxxx -u yyyyyyyyyy -m \"This is a test\" -U \"http://www.google.com\" --url-title Google"
        echo "  Sends a simple \"This is a test\" message to all devices that contains a link to www.google.com titled \"Google\"."
        echo
        echo "  ${script} -t xxxxxxxxxx -u yyyyyyyyyy -m \"This is a test\" -p 1"
        echo "  Sends a simple \"This is a test\" high priority message to all devices."
        echo
        echo "  ${script} -t xxxxxxxxxx -u yyyyyyyyyy -m \"This is a test\" -s bike"
        echo "  Sends a simple \"This is a test\" message to all devices that uses the sound of a bike bell as the notification sound."
        echo
        echo "  ${script} -t xxxxxxxxxx -u yyyyyyyyyy -m \"This is a test Pic\" -a /path/to/pic.jpg"
        echo "  Sends a simple \"This is a test Pic\" message to all devices and send the Picture with the message."
        echo
}

curl --version > /dev/null 2>&1 || { echo "This script requires curl; aborting."; echo; exit 1; }

if [ -f ${DEFAULT_CONFIG} ]; then
  source ${DEFAULT_CONFIG}
fi
if [ -f ${USER_OVERRIDE} ]; then
  source ${USER_OVERRIDE}
fi
if [ -f ${USER_OVERRIDE_PROJECT} ]; then
  source ${USER_OVERRIDE_PROJECT}
fi

declare -A myargs
varname=''

while [ $# -gt 0 ]
do
  if [ ${1:0:1} = '-' ]; then
    case "${1:-}" in
      -t|--token)
        varname='api_token'
        ;;

      -u|--user)
        varname='user_key'
        ;;

      -m|--message)
        varname='message'
        ;;

      -a|--attachment)
        varname='attachment'
        ;;

      -T|--title)
        varname='title'
        ;;

      -d|--device)
        varname='device'
        ;;

      -U|--url)
        varname='url'
        ;;

      --url-title)
        varname='url_title'
        ;;

      -H|--html)
        varname=''
        html=1
        ;;

      -M|--monospace)
        varname=''
        monospace=1
        ;;

      -D|--debug)
        varname=''
        debug=1
        ;;

      -p|--priority)
        varname='priority'
        ;;

      -s|--sound)
        varname='sound'
        ;;

      -e|--expire)
        varname='expire'
        ;;

      -r|--retry)
        varname='retry'
        ;;

      -v|--verbose)
        varname=''
        HIDE_REPLY=0
        ;;

      -x|--validate)
        varname=''
        VALIDATE=1
        ;;

      -h|--help)
        showHelp
        exit
        ;;

      *)
        ;;
    esac
  fi
  if [ -n "${varname}" ]; then
    if [[ ! -v "myargs[${varname}]" ]] ; then
      myargs[${varname}]=''
    fi
    if [ ${1:0:1} != '-' ]; then
      # priority
      if [ ${varname} == 'priority' ]; then
        pval=`printf -v int '%d\n' "${1}" 2>/dev/null`
        if [ $? -ne 0 ]; then
          echo "Priority must be an integer. You gave: ${1}"
          exit 4
        fi
        myargs[${varname}]=${pval}
      else
        myargs[${varname}]="${myargs[${varname}]} ${1}"
      fi  
    fi
  fi
  shift
done

for i in "${!myargs[@]}"
do
  # yes, i know eval is bad, but i'm not a bash guru.
  # if you have a better way, let me know.
  eval "${i}"='$(echo ${myargs[$i]} | xargs)'
  if [ ${debug} -eq 1 ]; then
    echo "DEBUG: arg-> ${i}=$(echo ${myargs[$i]} | xargs)"
  fi
done

if [ ${priority:-0} -eq 2 ]; then
  if [ -z "${expire:-}" ]; then
    expire=${EXPIRE_DEFAULT}
  fi
  if [ -z "${retry:-}" ]; then
    retry=${RETRY_DEFAULT}
  fi
fi

if [ -z "${api_token:-}" ]; then
  echo "-t|--token must be set"
  exit 1
elif [ ${debug} -eq 1 ]; then
  echo "DEBUG: api_token:${api_token}"
fi

if [ -z "${user_key:-}" ]; then
  echo "-u|--user must be set"
  exit 1
elif [ ${debug} -eq 1 ]; then
  echo "DEBUG: user_key:${user_key}"
fi

if [ -z "${message:-}" ]; then
  echo "-m|--message must be set"
  exit 1
elif [ ${debug} -eq 1 ]; then
  echo "DEBUG: message:${message}"
fi

if [ ${debug} -eq 1 ]; then
  echo "DEBUG: title:${title:-}"
fi

if [ ! -z "${html:-}" ] && [ ! -z "${monospace:-}" ]; then
  echo "--html and --monospace are mutually exclusive"
  exit 1
fi

if [ ! -z "${attachment:-}" ] && [ ! -f "${attachment}" ]; then
  echo "${attachment} not found"
  exit 1
fi

URL=${API_URL}
if [ ${VALIDATE} -eq 1 ]; then
  URL=${API_URL_VALIDATE}
fi
if [ ${debug} -eq 1 ]; then
    echo "DEBUG: VALIDATE=${VALIDATE}"
    echo "DEBUG: URL=${URL}"
  fi

if [ -z "${attachment:-}" ]; then
  if [ ${debug} -eq 1 ]; then
    echo "DEBUG: no attachment"
  fi
  json="{\"token\":\"${api_token}\",\"user\":\"${user_key}\",\"message\":\"${message}\""
  if [ "${device:-}" ]; then json="${json},\"device\":\"${device}\""; fi
  if [ "${title:-}" ]; then json="${json},\"title\":\"${title}\""; fi
  if [ "${url:-}" ]; then json="${json},\"url\":\"${url}\""; fi
  if [ "${url_title:-}" ]; then json="${json},\"url_title\":\"${url_title}\""; fi
  if [ "${html:-}" ]; then json="${json},\"html\":1"; fi
  if [ "${monospace:-}" ]; then json="${json},\"monospace\":1"; fi
  if [ "${priority:-}" ]; then json="${json},\"priority\":${priority}"; fi
  if [ "${expire:-}" ]; then json="${json},\"expire\":${expire}"; fi
  if [ "${retry:-}" ]; then json="${json},\"retry\":${retry}"; fi
  if [ "${sound:-}" ]; then json="${json},\"sound\":\"${sound}\""; fi
  json="${json}}"

  response=$(curl -s \
    -H "Content-Type: application/json" \
    -d "${json}" \
    "${URL}" 2>&1)
else
  if [ ${debug} -eq 1 ]; then
    echo "DEBUG: using attachment"
  fi
  response=$(curl -s \
    --form-string "token=${api_token}" \
    --form-string "user=${user_key}" \
    --form-string "message=${message}" \
    --form "attachment=@${attachment}" \
    ${html:+ --form-string "html=1"} \
    ${monospace:+ --form-string "monospace=1"} \
    ${priority:+ --form-string "priority=${priority}"} \
    ${sound:+ --form-string "sound=${sound}"} \
    ${device:+ --form-string "device=${device}"} \
    ${title:+ --form-string "title=${title}"} \
    "${URL}" 2>&1)
fi

if [ ${HIDE_REPLY} -eq 0 ]; then
  echo ${response}
fi

# the resonse from pushover is a failure when the status is 0
if echo ${response} | grep -q '"status":0,'; then
  exit 3
fi

exit 0
