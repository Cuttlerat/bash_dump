#!/usr/bin/env bash

# It is a Telegram bot for transporting all messages sent to bot into specific chat

set -euo pipefail
[[ "${TRACE:-}" ]] && set -x


readonly API="!!!!!!!CHANGE_ME!!!!!!!"
readonly CHAT_ID="!!!!!!!CHANGE_ME!!!!!!!"
readonly URL="https://api.telegram.org/bot${API}"
readonly TIMEOUT=10

send_message() {
    local TEXT=$( sed 's/^\s\+//g' <<< "${1}" )
    curl -s "${URL}/sendMessage"                                              \
            --max-time "${TIMEOUT}"                                           \
            --output /dev/null                                                \
            --data-urlencode "text=${TEXT}"                                   \
                      --data "chat_id=${CHAT_ID}"                             
}

offset() {
    local UPDATE_ID="$(( $1 + 1 ))"
    curl -s "${URL}/getUpdates" \
         --data "offset=${UPDATE_ID}" \
         -o /dev/null
}

main() {

    while raw_message=$(curl -s "${URL}/getUpdates"); do
        msg_count=$(jq '.result | length' <<<"${raw_message}")

        for i in $( seq 0 "${msg_count:=-1}"); do
            if [[ $(jq -r ".result[${i}].message.chat.type" <<<"${raw_message}") != "private" ]]; then
                continue
            fi
            UPDATE_ID=$(jq -r ".result[${i}].update_id" <<<"${raw_message}")
            TEXT=$(jq -r ".result[${i}].message.text" <<<"${raw_message}")
            send_message "${TEXT}"
            offset "${UPDATE_ID}"
        done
    done

}

main "$@"
