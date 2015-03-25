#!/bin/bash

shopt -s extglob
. /root/.PASSPHRASE

NONE='\033[00m'
RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
BOLD='\033[1m'

YEDEKCI_BACKEND_1="gs://backup-bucket"
YEDEKCI_BACKEND_2="scp://user@server:22/backup/directory"

YEDEKCI_ACTION=""
YEDEKCI_URL=""
YEDEKCI_COMPARE_DATA=""
YEDEKCI_TIME=0
YEDEKCI_FILE_TO_RESTORE=
YEDEKCI_LOCAL_PATH=""

displayWelcomeMessage() {
        echo
        echo "################################################################"
        echo -e "# Welcome to the ${GREEN}YEDEKCI${NONE} script.                               #"
        echo "# This is an interactive wrapper written for duplicity.        #"
        echo "# The goal is to make newbie sysadmins' job easier to perform. #"
        echo "# Copyright (c) 2015, Cagri Emer - 3 Clause BSD Licence        #"
        echo "################################################################"
        echo
}

askQuestion() {
        echo -n "$1: "
        read -r user_input
}

selectBackend() {
        echo "Two backends available."
        echo "For Google Cloud Storage, enter 1"
        echo "For SCP server, enter 2"
        askQuestion "Your selection [1, 2]"
}

selectAction() {
        echo "Available actions are;"
        echo
        echo -e "${RED}verify${NONE}"
        echo -e "${RED}restore${NONE}"
        echo
        askQuestion "Select an action to perform [v, r]"
}

isValidBackendAnswer() {
        if [[ $user_input = @([12]) ]]; then
                invalid_input=0
                if [[ $user_input = 1 ]]; then
                        YEDEKCI_URL=$YEDEKCI_BACKEND_1
               else
                        YEDEKCI_URL=$YEDEKCI_BACKEND_2
                fi
        else
                invalid_input=1
                while [[ $invalid_input = 1 ]]; do
                        echo "This is not a valid answer!"
                        askQuestion "Please enter 1 or 2"
                        isValidBackendAnswer
                done
        fi
}

isValidActionAnswer() {
        case $user_input in
                [Vv] ) YEDEKCI_ACTION="verify";;
                [Rr] ) YEDEKCI_ACTION="restore";;
                * ) YEDEKCI_ACTION="";;
    esac
    if [[ $YEDEKCI_ACTION = "" ]]; then
        echo "This is not a valid action."
        askQuestion "Please enter a valid action [v, r]"
        isValidActionAnswer
    fi
}

isValidIntegerAnswer() {
        if [[ $user_input = +([0-9]) ]]; then
                invalid_input=0
        else
                invalid_input=1
                while [[ $invalid_input = 1 ]]; do
                        echo "This is not a valid answer!"
                        askQuestion "Please enter an integer"
                        isValidIntegerAnswer
                done
        fi
}

isValidBoolAnswer() {
        if [[ $user_input = @([yYnN]) ]]; then
                invalid_input=0
        else
                invalid_input=1
                while [[ $invalid_input = 1 ]]; do
                        echo "This is not a valid answer!"
                        askQuestion "Please enter yes or no [y, n]"
                        isValidBoolAnswer
                done
        fi
}

#isValidPathAnswer() {
#        if ! [[ -e $user_input ]]; then
#                echo "This path does not exist."
#                askQuestion "Please enter a path"
#                isValidPathAnswer
#        fi
#}

displayActionHelp() {
        case $YEDEKCI_ACTION in
                verify ) displayVerifyHelp;;
                restore) displayRestoreHelp;;
        esac
}

displayVerifyHelp() {
        echo
        echo "General form of the verify command is as follows;"
        echo
        echo -e "${YELLOW}duplicity verify [--compare-data] [--time <T>] \\
                 [--file-to-restore <F>] <backend> <local_path>${NONE}\n"
        echo
        echo "Decisions to be made are as follows;"
        echo
        echo "1) --compare-data, ON or OFF"
        echo "2) --time, Should latest backup or <T> days old backup be used"
        echo "3) --file-to-restore, Verify a specific path or the whole backup"
        echo "4) --local-path, Where do you keep the local file to be verified"
        echo
}

displayRestoreHelp() {
        echo
        echo "General form of the restore command is as follows;"
        echo
        echo -e "${YELLOW}duplicity restore [--file-to-restore <F>] \\
                 [--time <T>] <backend> <target_directory>${NONE}\n"
        echo
        echo "Decisions to be made are as follows;"
        echo
        echo "1) --file-to-restore, Restore a specific path or the whole backup"
        echo "2) --time, Should latest backup or <T> days old backup be used"
        echo "3) <target_directory>, Where do you want to put the restored files"
    echo
}

askActionQuestions() {
        case $YEDEKCI_ACTION in
                verify ) askVerifyQuestions;;
                restore) askRestoreQuestions;;
        esac
}

askVerifyQuestions() {
        askQuestion "--compare-data flag should be ON [y, n]"
        isValidBoolAnswer
        if [[ $user_input = @([yY]) ]]; then
                YEDEKCI_COMPARE_DATA="--compare-data"
        fi

        askQuestion "Which backup should be used, enter 0 for latest [integer]"
        isValidIntegerAnswer
        if [[ $user_input != 0 ]]; then
                YEDEKCI_TIME=$user_input
      fi

        askQuestion "Should we verify the whole backup [y, n]"
        isValidBoolAnswer
        if [[ $user_input = @([yY]) ]]; then
                YEDEKCI_FILE_TO_RESTORE=""
        else
                askQuestion "Please enter the relative path that is going to be verified [e.g. forum/index.php]"
                YEDEKCI_FILE_TO_RESTORE=$user_input
        fi

        askQuestion "Where do you keep the original file [/my/local/file]"
#        isValidPathAnswer
        YEDEKCI_LOCAL_PATH=$user_input
}

askRestoreQuestions() {
        askQuestion "Should we restore the whole backup [y, n]"
        isValidBoolAnswer
        if [[ $user_input = @([yY]) ]]; then
                YEDEKCI_FILE_TO_RESTORE=""
        else
                askQuestion "Please enter the relative path that is going to be restored [e.g. forum/index.php]"
                YEDEKCI_FILE_TO_RESTORE=$user_input
        fi

        askQuestion "Which backup should be used, enter 0 for latest [integer]"
        isValidIntegerAnswer
        if [[ $user_input != 0 ]]; then
                YEDEKCI_TIME=$user_input
        fi

        askQuestion "Where do you want to put the restored files [/my/local/file]"
#        isValidPathAnswer
        YEDEKCI_LOCAL_PATH=$user_input
}

constructCommand() {
        if [[ $YEDEKCI_ACTION = "verify"  ]]; then
            runCommand="duplicity $YEDEKCI_ACTION -v4 --encrypt-sign-key 4D0AC07F $YEDEKCI_COMPARE_DATA --time 
$YEDEKCI_TIME --file-to-restore $YEDEKCI_FILE_TO_RESTORE $YEDEKCI_URL $YEDEKCI_LOCAL_PATH"
            runDryCommand="duplicity $YEDEKCI_ACTION --dry-run -v4 --encrypt-sign-key 4D0AC07F 
$YEDEKCI_COMPARE_DATA --time $YEDEKCI_TIME --file-to-restore $YEDEKCI_FILE_TO_RESTORE $YEDEKCI_URL 
$YEDEKCI_LOCAL_PATH"
	else
            runCommand="duplicity $YEDEKCI_ACTION -v4 --encrypt-sign-key 4D0AC07F --time $YEDEKCI_TIME 
--file-to-restore $YEDEKCI_FILE_TO_RESTORE $YEDEKCI_URL $YEDEKCI_LOCAL_PATH"
            runDryCommand="duplicity $YEDEKCI_ACTION --dry-run -v4  --encrypt-sign-key --time $YEDEKCI_TIME 
--file-to-restore $YEDEKCI_FILE_TO_RESTORE $YEDEKCI_URL $YEDEKCI_LOCAL_PATH"
        fi
}

verifyCommandAndRun() {
        echo -e "${RED}$runCommand${NONE}"
        askQuestion "Is this the command you want to run [y, n]"
        isValidBoolAnswer
        if [[ $user_input != @([yY]) ]]; then
                echo "Exiting! Start again."
                exit 0
        else
               askQuestion "Dry run to test it first [y, n]"
               isValidBoolAnswer
               if [[ $user_input = @([yY]) ]]; then
                    echo "Running with --dry-run"
                    eval $runDryCommand
                    exit 0
               else
                    echo "Running actual command"
                    eval $runCommand
                    exit 0
               fi

        fi
}

cleanUp() {
        tput sgr0
#        unset $PASSPHRASE
}

main() {
        displayWelcomeMessage
        selectBackend
        isValidBackendAnswer
        selectAction
        isValidActionAnswer
        displayActionHelp
        askActionQuestions
        constructCommand
        verifyCommandAndRun
        cleanUp
}

main
