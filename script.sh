#! /bin/bash

# Gather user input
printf "What is the location of your monorepo?\n"
read MONOREPO
printf "What is the location of the repository you'd like to put in your monorepo (RTPIM)?\n"
read RTPIM
printf "What Git commit prefix would you like you to add to the commits in your RTPIM? Leave blank for none."
read commitPrefix

# Start script work
# Create git repo if monorepo doesn't exist
if [ ! -d "$MONOREPO" ]; then
	HOME_DIRECTORY=`echo $PWD`
	mkdir $MONOREPO
	cd $MONOREPO
	git init
	touch CHANGELOG
	cd $HOME_DIRECTORY
	printf "\nCREATED NEW GIT REPOSITORY AT \"$MONOREPO\"."
fi

# Check RTPIM directory exists
if [ -d "$RTPIM" ]; then
	cd $RTPIM
else
	printf "\nWARNING! \"$RTPIM\" IS NOT A DIRECTORY! EXITING."
	exit
fi

# Check for all branches of the repo and loop through them in succession
GIT_BRANCH_REGEX="((([-0-9a-zA-Z\/_?:.,]+)$)|(([-0-9a-zA-Z\/_?:.,]+(  ))$))"
RAW_GIT_BRANCHES=`git branch -a`
printf "$RAW_GIT_BRANCHES"

# https://unix.stackexchange.com/a/628576
set -o noglob
IFS=$'\n' ARRAY_GIT_BRANCHES=($RAW_GIT_BRANCHES)
set +o noglob

# A bunch of stuff I tried that didn't work
# CLEANED_GIT_BRANCHES=$(echo $RAW_GIT_BRANCHES | grep -qE "{GIT_BRANCH_REGEX}")
# IFS='\n\b' read -ra ARRAY_GIT_BRANCHES <<< "$rawGitBranches"
# IFS=$'\n' read -rd '' -a ARRAY_GIT_BRANCHES <<<"$rawGitBranches"

for i in ${ARRAY_GIT_BRANCHES[@]} 
do

	# Clean up git branch name using Regex
	printf $i
	CLEANED_GIT_BRANCH_NAME=$(echo '$i' | grep -P -q '$GIT_BRANCH_REGEX')
	printf $CLEANED_GIT_BRANCH_NAME

	# Checkout the branch in the current loop, before heading back to the monorepo
	git checkout $CLEANED_GIT_BRANCH_NAME

	# Head to the monorepo and 
	cd ../$MONOREPO
	git subtree add --prefix=$RTPIM/master ../$RTPIM master

	printf "`tree -L 2`"
	printf "Added to changelog: %s\n" 
	CURRENT_DATE=`date +"%Y-%m-%d %T`
	echo $CURRENT_DATE

done
