#! /bin/bash

# STEP 1: Gather user input
printf "What is the location of your monorepo?\n"
read MONOREPO
printf "What is the location of the repository you'd like to put in your monorepo (RTPIM)?\n"
read RTPIM

# printf "What Git commit prefix would you like you to add to the commits in your RTPIM? Leave blank for none."
# read commitPrefix

# Definitions
CHANGELOG='changelog.md'
GIT_BRANCH_REGEX="((([-0-9a-zA-Z\/_?:.,]+)$)|(([-0-9a-zA-Z\/_?:.,]+(  ))$))"
TOP_LEVEL_DIRECTORY=`echo $PWD`

# STEP 2: Check paths
# Create git repo if monorepo doesn't exist
if [ ! -d "$MONOREPO" ]; then
	mkdir $MONOREPO
	cd $MONOREPO
	git init
	touch $CHANGELOG
	git add --all
	git commit -m "initialize repository"
	cd $TOP_LEVEL_DIRECTORY
	printf "\nCREATED NEW GIT REPOSITORY AT \"$MONOREPO\"."
fi

printf "$TOP_LEVEL_DIRECTORY"

# Check RTPIM directory exists
if [ -d "$RTPIM" ]; then
	cd $RTPIM
else
	printf "\nWARNING! \"$RTPIM\" IS NOT A DIRECTORY! EXITING.\n"
	exit
fi

for branch in $(git branch --all | grep '^\s*remotes' | egrep --invert-match '(:?HEAD|master)$'); do
    git branch --track "${branch##*/}" "$branch"
done
# ^ Taken from https://stackoverflow.com/a/4754797

cd $TOP_LEVEL_DIRECTORY/$MONOREPO

touch $CHANGELOG
CHANGELOG_HEADER="## Add branches from monorepo to RTPIM"
echo "$CHANGELOG_HEADER" >> $CHANGELOG
printf "$CHANGELOG_HEADER"

cd $TOP_LEVEL_DIRECTORY/$RTPIM

# Reset git and checkout to avoid "Working tree has modifications." issue
# https://stackoverflow.com/a/18608538
git reset
git checkout

# STEP 3: Gather all git branches from $RTPIM into array
# Check for all branches of the repo and loop through them in succession
RAW_GIT_BRANCHES=`git branch`
printf "$RAW_GIT_BRANCHES"

set -o noglob
IFS=$'\n' ARRAY_GIT_BRANCHES=($RAW_GIT_BRANCHES)
set +o noglob
# ^ from https://unix.stackexchange.com/a/628576

# A bunch of stuff I tried that didn't work
# CLEANED_GIT_BRANCHES=$(echo $RAW_GIT_BRANCHES | grep -qE "{GIT_BRANCH_REGEX}")
# IFS='\n\b' read -ra ARRAY_GIT_BRANCHES <<< "$rawGitBranches"
# IFS=$'\n' read -rd '' -a ARRAY_GIT_BRANCHES <<<"$rawGitBranches"

# STEP 4: Loop through array of git branches and add each branch from $RTPIM as a subtree in $MONOREPO, in directory $MONOREPO/$RTPIM/$BRANCH_NAME
for BRANCH in ${ARRAY_GIT_BRANCHES[@]} 
do
	
	# Clean up git branch name using Regex
	# IGNORE: BRANCH=$(echo "$BRANCH" | grep -E '((([-0-9a-zA-Z\/_?:.,]+)$)|(([-0-9a-zA-Z\/_?:.,]+(  ))$))')
	BRANCH=$(sed 's/^[ *]*\([^ ]*\).*/\1/' <<< $BRANCH)
	# https://stackoverflow.com/questions/51668837/remove-a-from-a-line-using-sed
	# https://stackoverflow.com/questions/6744006/can-i-use-sed-to-manipulate-a-variable-in-bash
	
	FULLY_CLEANED_GIT_BRANCH_NAME=$(echo "$BRANCH" | awk '$1=$1')

	printf "$FULLY_CLEANED_GIT_BRANCH_NAME"

	# Checkout the branch in the current loop, before heading back to the monorepo
	git checkout $FULLY_CLEANED_GIT_BRANCH_NAME

	# Head to the monorepo and begin Git logic
	cd $TOP_LEVEL_DIRECTORY/$MONOREPO
	git subtree add --prefix=$RTPIM/$FULLY_CLEANED_GIT_BRANCH_NAME ../$RTPIM $FULLY_CLEANED_GIT_BRANCH_NAME
	
	# Report results
	printf "\nADDED TO CHANGELOG: %s\n" 
	CURRENT_DATE=`date +"%Y-%m-%d %T"`
	CHANGELOG_MESSAGE="At $CURRENT_DATE, branch \"\`$FULLY_CLEANED_GIT_BRANCH_NAME\`\" from repository \"\`$RTPIM\`\" was added to monorepo: \"\`$MONOREPO\`\", in path \"\`$RTPIM/$FULLY_CLEANED_GIT_BRANCH_NAME\`\""
	printf "⦿ $CHANGELOG_MESSAGE \n"
	echo "- $CHANGELOG_MESSAGE" >> $CHANGELOG

	git add --all 
	git commit -m "Update changelog"
	
	# Head back to $RTPIM directory to begin loop again
	cd $TOP_LEVEL_DIRECTORY/$RTPIM	
done

cd $TOP_LEVEL_DIRECTORY/$MONOREPO
printf "\n\nNew tree structure of your monorepo:\n`tree -L 2`"

cd $TOP_LEVEL_DIRECTORY

printf "\n\nFINISHED!!!\n"
