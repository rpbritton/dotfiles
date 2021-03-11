#!/bin/sh


while read FILE
do
    if [[ -z $FILE ]]
    then
        echo "No files found"
        break
    fi

    if [[ -z $OUTPUT ]]
    then
        OUTPUT=output
        rm -rf $OUTPUT
        mkdir -p $OUTPUT
    fi

    NEW="./output/$(basename $FILE .ovpn).conf"

    cp $FILE $NEW

    sed -i '/^auth-user-pass/d' $NEW
    echo "auth-user-pass pass.txt" >> $NEW
    echo "auth-nocache" >> $NEW
done <<<$(find . -maxdepth 1 -name "*.ovpn")