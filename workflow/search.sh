#!/bin/bash

# see https://docs.cyberduck.io/cyberduck/faq/#preferences-and-application-support-files-location
BOOKMARK_PATH="${APP_SUPPORT_PATH/#~/$HOME}Bookmarks"
QUERY=$(tr '[A-Z]' '[a-z]' <<<"$1")

ITEM_TEMPLATE='{"title": "!@#title", "subtitle": "!@#subtitle", "icon": {"path": "assets/images/bookmark.png"}, "arg": "!@#arg"},'

getItem() {
    local path=$1
    while IFS= read -r line; do
        key=$(sed -n "s|^[[:blank:]]<key>\(.*\)</key>|\1|p" <<<"$line")
        if [[ -n "$key" ]]; then
            pre_key=$key
        else
            str=$(sed -n "s|^[[:blank:]]<string>\(.*\)</string>|\1|p" <<<"$line")

            case $pre_key in
            "Protocol")
                protocol=$(tr '[a-z]' '[A-Z]' <<<$str)
                ;;
            "Nickname")
                nickname=$str
                ;;
            "Hostname")
                hostname=$str
                ;;
            "Port")
                port=$str
                ;;
            "Username")
                username=$str
                ;;
            esac
        fi
    done <"$path"

    filtering_txt=$(echo "$nickname" "$username" "$hostname" "$port" | tr '[A-Z]' '[a-z]')

    if [[ -z "$QUERY" || $filtering_txt == *"$QUERY"* ]]; then
        sed -e "s|!@#title|$nickname|" \
            -e "s|!@#subtitle|[$protocol] $hostname:$port - $username|" \
            -e "s|!@#arg|$path|" <<<"$ITEM_TEMPLATE"
    fi
}

declare -a bookmark_paths=("$BOOKMARK_PATH"/*)
declare -a bookmarks=()

while read -r bookmark_path; do
    item=$(getItem "$bookmark_path")
    if [[ -n "$item" ]]; then
        bookmarks+=($item)
    fi
done < <(printf "%s\n" "${bookmark_paths[@]}")

echo -n "{\"items\": [${bookmarks[@]}]}"
