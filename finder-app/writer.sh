#!/bin/bash

writefile=$1
writestr=$2
number_of_args=$#

if ! [[ $number_of_args -eq 2 ]];
then
	echo "Specifie two arguments"
	exit 1
fi

#if ! [[ -f "$number_of_args" ]];
#then
#	echo "First argument must be a file"
#	exit
#fi

mkdir -p "$(dirname "$writefile")" && touch "$writefile" && echo "$writestr "> "$writefile"


