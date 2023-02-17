#!/bin/sh

number_of_args=$#
filesdir=$1
searchstr=$2

if ! [[ $number_of_args -eq 2 ]]
then
	echo "Pass in two parameter, $0 filesdir searchstr"
	exit 1
fi


if ! [[ -d $filesdir ]]
then
echo "First argument should be a directory"
exit 1
fi

echo "The number of files are $(grep -Rl "$searchstr" $filesdir | wc -l) and the number of matching lines are $(grep -R $searchstr $filesdir | wc -l)"

