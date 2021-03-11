#!/bin/bash

for f in $(basename --suffix=.md *.md)
do
	if [[ ! -f $f.md ]]
	then
		echo "No markdown files found"
		exit 1
	fi

	echo "Compiling '$f.md' into '$f.pdf'"
	pandoc -s $f.md -o $f.pdf \
		-f markdown-implicit_figures \
		--highlight-style=tango
done
