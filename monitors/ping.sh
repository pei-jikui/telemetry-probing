#!/bin/sh

# ----------------------------------------------------------------------------------------
# You pass the whole ping output as input stream, and this produces the JSON of it.
# You can do like this (e.g.):
#    ping-script/ping_to_json.sh  $host
# ----------------------------------------------------------------------------------------

# cd to the current directory as it runs other shell scripts
host=`echo $1 | sed 's/::ffff://'`
rtt_statistics()
{
    RTT_LINE=$1

    if [ -z "${RTT_LINE}" ]; then
        >&2 echo 'ERROR: std input for the RTT statistics line is empty'
        return 1
    elif ! echo "${RTT_LINE}" | grep -q "rtt min/avg/max/mdev" ; then
        >&2 echo 'ERROR: std input for the RTT statistics line does not start with "rtt min/avg/max/mdev":'
        >&2 echo ">${RTT_LINE}"
        return 1
    elif [ "$(echo "${RTT_LINE}" | wc -l)" -ne 1 ]; then
        >&2 echo 'ERROR: Multiple lines in std input for the RTT statistics line:'
        >&2 echo ">${RTT_LINE}"
        return 1
    else
        # Parse the line (e.g.) "rtt min/avg/max/mdev = 97.749/98.197/98.285/0.380 ms"

        # part-by-part validation
        FIRST_PART=$(echo "${RTT_LINE}"  | awk '{print $1}') # "rtt"
        SECOND_PART=$(echo "${RTT_LINE}" | awk '{print $2}') # "min/avg/max/mdev"
        THIRD_PART=$(echo "${RTT_LINE}"  | awk '{print $3}') # "="
        FOURTH_PART=$(echo "${RTT_LINE}" | awk '{print $4}') # (e.g.) "97.749/98.197/98.285/0.380"
        FIFTH_PART=$(echo "${RTT_LINE}"  | awk '{print $5}') # (e.g.) "ms"

        if [ "${FIRST_PART}" != "rtt" ] ; then
            >&2 echo "ERROR: '${FIRST_PART}' is not equal to 'rtt', in the below RTT line:"
            >&2 echo ">${RTT_LINE}"
            return 1
        elif [ "${SECOND_PART}" != "min/avg/max/mdev" ] ; then
            >&2 echo "ERROR: '${SECOND_PART}' is not equal to 'min/avg/max/mdev', in the below RTT line:"
            >&2 echo ">${RTT_LINE}"
            return 1
        elif [ "${THIRD_PART}" != "=" ] ; then
            >&2 echo "ERROR: '${THIRD_PART}' is not equal to '=', in the below RTT line:"
            >&2 echo ">${RTT_LINE}"
            return 1
            # FOURTH_PART to be validated later
        elif [ -n "$(echo "${FIFTH_PART}" | awk "/[1-9]/")" ]; then
            >&2 echo "ERROR: '${FIFTH_PART}' should not include any digit, in the below RTT line:"
            >&2 echo ">${RTT_LINE}"
            return 1
        fi

        # Validate and retrieve values from FOURTH_PART
        # (e.g.) "97.749/98.197/98.285/0.380"
        RTT_MIN=$(echo "${FOURTH_PART}" | awk -F'/' '{print $1}'| awk '/^[+-]?([0-9]*[.])?[0-9]+$/')
        if [ -z "${RTT_MIN}" ]; then
            >&2 echo "ERROR: Cannot retrieve the first number from '${FOURTH_PART}', in the below RTT line:"
            >&2 echo ">${RTT_LINE}"
            return 1
        fi
        # (e.g.) "97.749/98.197/98.285/0.380"
        RTT_AVG=$(echo "$FOURTH_PART" | awk -F'/' '{print $2}'| awk '/^[+-]?([0-9]*[.])?[0-9]+$/')
        if [ -z "${RTT_AVG}" ]; then
            >&2 echo "ERROR: Cannot retrieve the second number from '${FOURTH_PART}', in the below RTT line:"
            >&2 echo ">${RTT_LINE}"
            return 1
        fi
        # (e.g.) "97.749/98.197/98.285/0.380"
        RTT_MAX=$(echo "$FOURTH_PART" | awk -F'/' '{print $3}'| awk '/^[+-]?([0-9]*[.])?[0-9]+$/')
        if [ -z "${RTT_MAX}" ]; then
            >&2 echo "ERROR: Cannot retrieve the third number from '${FOURTH_PART}', in the below RTT line:"
            >&2 echo ">${RTT_LINE}"
            return 1
        fi
        # (e.g.) "97.749/98.197/98.285/0.380"
        RTT_MDEV=$(echo "$FOURTH_PART" | awk -F'/' '{print $4}'| awk '/^[+-]?([0-9]*[.])?[0-9]+$/')
        if [ -z "${RTT_MDEV}" ]; then
            >&2 echo "ERROR: Cannot retrieve the fourth number from '${FOURTH_PART}', in the below RTT line:"
            >&2 echo ">${RTT_LINE}"
            return 1
        fi

        RTT_UNIT=$(echo "${RTT_LINE}" | awk '{print $5}')
        case "$RTT_UNIT" in
            ms)
                RTT_UNIT="milliseconds"
                ;;
            s)
                RTT_UNIT="seconds"
                ;;
        esac

        echo "unit=\"${RTT_UNIT}\",min=\"${RTT_MIN}\",avg=\"${RTT_AVG}\",max=\"${RTT_MAX}\",mdev=\"${RTT_MDEV}\""
    fi
}

rtt_summary()
{
    SUMMARY_LINE="$1"

    if [ -z "${SUMMARY_LINE}" ]; then
        >&2 echo 'ERROR: std input for the RTT summary line is empty'
        return 1
    elif ! echo "${SUMMARY_LINE}" | grep "packets transmitted, " | grep "received, " | grep " packet loss, " | grep -q "time " ; then
        >&2 echo 'ERROR: std input for the RTT summary line is not in the form of "** packets transmitted, ** received, *% packet loss, time ****ms"'
        >&2 echo ">${SUMMARY_LINE}"
        return 1
    elif [ "$(echo "${SUMMARY_LINE}" | wc -l)" -ne 1 ]; then
        >&2 echo 'ERROR: Multiple lines in std input for the RTT summary line:'
        >&2 echo ">${SUMMARY_LINE}"
        return 1
    else
        # Parse the line (e.g.) "30 packets transmitted, 30 received, 0% packet loss, time 29034ms"

        # part-by-part validation
        FIRST_PART=$(echo "${SUMMARY_LINE}"  | awk -F',' '{print $1}') # (e.g.) "30 packets transmitted"
        SECOND_PART=$(echo "${SUMMARY_LINE}" | awk -F',' '{print $2}') # (e.g.) " 30 received"
        THIRD_PART=$(echo "${SUMMARY_LINE}"  | awk -F',' '{print $3}') # (e.g.) " 0% packet loss"
        FOURTH_PART=$(echo "${SUMMARY_LINE}" | awk -F',' '{print $4}') # (e.g.) " time 29034ms"

        if [ -z "$(echo "${FIRST_PART}" | awk "/^[0-9]+\spackets\stransmitted$/")" ] ; then
            >&2 echo "ERROR: '${FIRST_PART}' is not in the form of '** packets transmitted', from the below summary line:"
            >&2 echo ">${SUMMARY_LINE}"
            return 1
        elif [ -z "$(echo "${SECOND_PART}" | awk "/^\s[0-9]+\sreceived$/")" ] ; then
            >&2 echo "ERROR: '${SECOND_PART}', is not in the form of ' ** received', from the below summary line:"
            >&2 echo ">${SUMMARY_LINE}"
            return 1
        elif [ -z "$(echo "${THIRD_PART}" | awk "/^\s[0-9]+\%\spacket\sloss$/")" ] ; then
            >&2 echo "ERROR: '${THIRD_PART}', is not in the form of ' **% packet loss', from the below summary line:"
            >&2 echo ">${SUMMARY_LINE}"
            return 1
        elif [ -z "$(echo "${FOURTH_PART}" | awk "/^\stime\s[0-9]+[a-z]{1,2}$/")" ]; then
            >&2 echo "ERROR: '${FOURTH_PART}', is not in the form of ' time **ms', from the below summary line:"
            >&2 echo ">${SUMMARY_LINE}"
            return 1
        fi

        # 1. Parse the "30 packets transmitted" part of the SUMMARY_LINE
        # (e.g.) "30 packets transmitted"
        PACKETS_TRANSMITTED=$(echo "${FIRST_PART}" | awk '{print $1}'| awk '/^[0-9]+$/')
        if [ -z "${PACKETS_TRANSMITTED}" ]; then
            >&2 echo "ERROR: Cannot retrieve the packets transmitted value from '${FIRST_PART}', in the below summary line:"
            >&2 echo ">${SUMMARY_LINE}"
            return 1
        fi
        # (e.g.) " 30 received"
        PACKETS_RECEIVED=$(echo "${SECOND_PART}" | awk '{print $1}'| awk '/^[0-9]+$/')
        if [ -z "${PACKETS_RECEIVED}" ]; then
            >&2 echo "ERROR: Cannot retrieve the packets received value from '${SECOND_PART}', in the below summary line:"
            >&2 echo ">${SUMMARY_LINE}"
            return 1
        fi
        # (e.g.) " 0% packet loss"
        PACKET_LOSS_PERCENTAGE=$(echo "${THIRD_PART}" | awk '{print $1}'| sed 's/%//')
        if [ -z "${PACKET_LOSS_PERCENTAGE}" ]; then
            >&2 echo "ERROR: Cannot retrieve the packet loss percentage from '${THIRD_PART}', in the below summary line:"
            >&2 echo ">${SUMMARY_LINE}"
            return 1
        fi
        # (e.g.)"time 29034ms"
        TIME_VALUE=$(echo "${FOURTH_PART}" | awk '{print $2}'| grep -o '^[0-9]*')
        if [ -z "${PACKETS_TRANSMITTED}" ]; then
            >&2 echo "ERROR: Cannot retrieve the time value from '${FOURTH_PART}', in the below summary line:"
            >&2 echo ">${SUMMARY_LINE}"
            return 1
        fi
        TIME_UNIT=$(echo "${FOURTH_PART}" | awk '{print $2}'| sed 's/^[0-9]*//')
        if [ -z "${PACKETS_TRANSMITTED}" ]; then
            >&2 echo "ERROR: Cannot retrieve the time unit from '${FOURTH_PART}', in the below summary line:"
            >&2 echo ">${SUMMARY_LINE}"
            return 1
        fi
        case "$TIME_UNIT" in
            ms)
                TIME_UNIT="milliseconds"
                ;;
            s)
                TIME_UNIT="seconds"
                ;;
        esac

        echo "packets_transmitted=\"${PACKETS_TRANSMITTED}\",packets_received=\"${PACKETS_RECEIVED}\",packet_loss_percentage=\"${PACKET_LOSS_PERCENTAGE}\",unit=\"${TIME_UNIT}\",time=\"${TIME_VALUE}\""
    fi

}

ping -c 5 -i 0.2 -n $host > /tmp/a.out 2>&1
if [ $? != 0 ]; then
    echo down
    exit
fi
while read -r line; do
  if echo "${line}" | grep -q "rtt min/avg/max/mdev" ; then
    if [ -n "${RTT_STATISTICS_JSON}" ]; then
      >&2 echo "ERROR: There must be only one RTT statistics line, but '${line}' appeared as another one. Previous RTT statistics is:"
      >&2 echo "${RTT_STATISTICS_JSON}"
      echo down
      exit 1
    else
        RTT_STATISTICS_JSON="$(rtt_statistics "${line}")"
    fi
  elif echo "${line}" | grep "packets transmitted, " | grep "received, " | grep " packet loss, " | grep -q "time " ; then
    if [ -n "${RTT_SUMMARY_JSON}" ]; then
      >&2 echo "ERROR: There must be only one RTT summary line, but '${line}' appeared as another one. Previous RTT summary is:"
      >&2 echo "${RTT_SUMMARY_JSON}"
      echo down
      exit 1
    else
        RTT_SUMMARY_JSON="$(rtt_summary "${line}")"
   fi
  fi
done < /tmp/a.out

output="host=\"${host}\",status=\"up\",${RTT_SUMMARY_JSON},${RTT_STATISTICS_JSON}"
echo ${output} | nc 127.0.0.1 6514

if [ -z "${RTT_STATISTICS_JSON}" ]; then
  >&2 echo "ERROR: RTT statistics line is not found, which starts with rtt min/avg/max/mdev"
  echo down
  exit 1
elif  [ -z "${RTT_SUMMARY_JSON}" ]; then
  >&2 echo "ERROR: RTT summary line is not found, which is like '** packets transmitted, ** received, *% packet loss, time ****ms'"
  echo down
  exit 1
fi

echo "on"
exit 0
