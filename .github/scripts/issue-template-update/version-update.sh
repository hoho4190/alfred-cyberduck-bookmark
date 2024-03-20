# body 배열 중 id가 version인 객체의 버전을 업데이트 함
# BRANCH_NAME="release/v1.5.0" CUR_VERSION="1.5.0" bash .github/scripts/template-version-update.sh bug-report.yml

#!/bin/bash

if [[ $# -ne 1 || -z $1 ]]; then
    echo "Usage: TEMPLATE_NAME"
    exit 1
elif [[ -z $BRANCH_NAME ]]; then
    echo "BRANCH_NAME is null"
    exit 1
elif [[ -z $CUR_VERSION ]]; then
    echo "BRANCH_NAME is null"
    exit 1
fi

TEMPLATE_PATH=".github/ISSUE_TEMPLATE/$1"

getTags() {
    gh release list --exclude-drafts --json tagName | jq \
        --arg d "v$CUR_VERSION" \
        '. += [{ "tagName": $d }] 
            | map(.tagName) 
            | sort 
            | reverse'
}

tags=$(getTags) yq -iP \
    '(.body[] | select(.id == "version") | .attributes.options)
        = env(tags)' "$TEMPLATE_PATH"

# remove (strip) all comments
yq -iP '... comments=""' "$TEMPLATE_PATH"

# add comments
echo -e "\n# Updated by $BRANCH_NAME\n# $(date -u)" >>"$TEMPLATE_PATH"
