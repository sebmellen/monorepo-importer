#! /bin/bash

# STEP 1: Gather user input
printf "What is the location of your monorepo?\n"
read MONOREPO
printf "What is the location of the repository you'd like to put in your monorepo (RTPIM)?\n"
read RTPIM
printf "What Git commit prefix would you like you to add to the commits in your RTPIM? Leave blank for none."
read commitPrefix

# STEP 2: Check paths
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

printf "$HOME_DIRECTORY"

# Check RTPIM directory exists
if [ -d "$RTPIM" ]; then
	cd $RTPIM
else
	printf "\nWARNING! \"$RTPIM\" IS NOT A DIRECTORY! EXITING.\n"
	exit
fi

	CHANGELOG='changelog.md'


# STEP 3: Gather all git branches from $RTPIM into array
# Check for all branches of the repo and loop through them in succession
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

echo "## Add branches from $RTPIM to $MONORPO, `date`" >> $CHANGELOG

# STEP 4: Loop through array of git branches and add each branch from $RTPIM as a subtree in $MONOREPO, in directory $MONOREPO/$RTPIM/$BRANCH_NAME
for BRANCH in ${ARRAY_GIT_BRANCHES[@]} 
do

	# Definitions
	CHANGELOG='changelog.md'
	GIT_BRANCH_REGEX="((([-0-9a-zA-Z\/_?:.,]+)$)|(([-0-9a-zA-Z\/_?:.,]+(  ))$))"
	
	# Clean up git branch name using Regex
	# IGNORE: PARTIALLY_CLEANED_GIT_BRANCH_NAME=$(echo "$BRANCH" | grep -E -P '((([-0-9a-zA-Z\/_?:.,]+)$)|(([-0-9a-zA-Z\/_?:.,]+(  ))$))')
	BRANCH=$(sed 's/^[ *]*\([^ ]*\).*/\1/' <<< $BRANCH)
	# https://stackoverflow.com/questions/51668837/remove-a-from-a-line-using-sed
	# https://stackoverflow.com/questions/6744006/can-i-use-sed-to-manipulate-a-variable-in-bash
	
	FULLY_CLEANED_GIT_BRANCH_NAME=$(echo "$BRANCH" | awk '$1=$1')

	# Checkout the branch in the current loop, before heading back to the monorepo
	git checkout $BRANCH

	# Head to the monorepo and begin Git logic
	cd ../$MONOREPO
	git subtree add --prefix=$RTPIM/$FULLY_CLEANED_GIT_BRANCH_NAME ../$RTPIM $FULLY_CLEANED_GIT_BRANCH_NAME
	
	# Report results
	printf "`tree -L 2`"
	printf "\n\nAdded to changelog: %s\n" 
	CURRENT_DATE=`date +"%Y-%m-%d %T"`
	CHANGELOG_MESSAGE="At $CURRENT_DATE, branch \"\`$FULLY_CLEANED_GIT_BRANCH_NAME\`\" from repository \"\`$RTPIM\`\" was added to monorepo: \"\`$MONOREPO\`\", in path \"\`$RTPIM/$FULLY_CLEANED_GIT_BRANCH_NAME\`\""
	printf "$CHANGELOG_MESSAGE \n"
	echo "- $CHANGELOG_MESSAGE" >> $CHANGELOG
	
 	# Head back to $RTPIM directory to begin loop again
       	cd ../$RTPIM	
done


cd $HOME_DIRECTORY
printf "\n\n FINISHED!!!\n"
