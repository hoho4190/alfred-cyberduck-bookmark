#!/bin/bash

OUTPUT_PATH="outputs"
WORKFLOW_PATH="workflow"
PLIST_FILE="$WORKFLOW_PATH/info.plist"

[[ -z $RELEASE_VERSION ]] && version="dev" || version=$RELEASE_VERSION

getValue() {
    local key=$1
    local is_key=false
    local value=
    while IFS= read -r line; do
        if [[ $line == [[:space:]]"<key>$key</key>" ]]; then
            is_key=true
        elif [[ $is_key == true && $line == [[:space:]]"<string>"* ]]; then
            value=$(sed -e "s/<string>//" -e "s/<\/string>//" <<<"$line")
            break
        fi
    done <$PLIST_FILE

    echo $value
}

updateVersion() {
    if [[ "$OSTYPE" =~ ^darwin ]]; then
        sed -i "" "s/{{VERSION}}/$version/" $PLIST_FILE
    else
        sed -i "s/{{VERSION}}/$version/" $PLIST_FILE
    fi
}

createAlfredworkflow() {
    rm -rf "$OUTPUT_PATH"
    mkdir -p "$OUTPUT_PATH"

    cd "$WORKFLOW_PATH" && zip -rq "../$1" .
}

# update to release version
updateVersion
if [[ $? -ne 0 ]]; then
    echo "Failed to update version."
    exit 1
fi

# create .alfredworkflow file
name=$(getValue "name" | tr ' ' '-' | tr '[A-Z]' '[a-z]')-
if [[ $version == "dev" ]]; then
    name+="$version"
else
    name+="v$version"
fi
file_name="$OUTPUT_PATH/$name.alfredworkflow"

createAlfredworkflow $file_name
if [[ $? -ne 0 ]]; then
    echo "Failed to create .alfredworkflow"
    exit 1
fi

echo "OUTPUT_PATH=$OUTPUT_PATH" >>"$GITHUB_OUTPUT"
