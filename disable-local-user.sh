#!/bin/bash

#This script disables, deletes, and/or archives users on the local system

ARCHIVE_DIR='/archive'

usage(){
    echo "Usage: ${0} [-dra] USER [USERN]..." >&2
    echo 'Disable a local Linux account.' >&2
    echo '  -d Deletes accounts instead of disabling them.' >&2
    echo '  -r Removes the home directory associated with the account(s).' >&2
    echo '  -a Creates an archive of the home directory associated with the account(s).' >&2
    exit 1
}

if [[ "${UID}" -ne 0 ]]
then
    echo 'Please run with sudo or root.' >&2
    exit 1
fi

while getopts dra OPTION
do
    case ${OPTION} in
        d) DELETE_USER='true' ;;
        r) REMOVE_OPTION='-r' ;;
        a) ARCHIVE='true' ;;
        ?) usage ;;
    esac
done

shift "$(( OPTIND - 1 ))"

if [[ "${#}" -lt 1 ]]
then
    usage
fi

for USERNAME in "${@}"
do
    echo "Processing user: ${USERNAME}"

    USERID=$(id -u ${USERNAME})
    if [[ "${USERID}" -lt 1000 ]]
    then
        echo "Refusing to remove the ${USERNAME} account with UID ${USERID}." >&2
        exit 1
    fi

    if [[ "${ARCHIVE}" = 'true' ]]
    then
        if [[ ! -d "${ARCHIVE_DIR}" ]]
        then
            echo "Creating ${ARCHIVE_DIR} directory."
            mkdir -p ${ARCHIVE_DIR}
            if [[ "${?}" -ne 0 ]]
            then
                echo "The archive directory ${ARCHIVE_DIR} could not be created." >&2
                exit 1
            fi
        fi


        HOME_DIR="/home/${USERNAME}"
        ARCHIVE_FILE="${ARCHIVE_DIR}/${USERNAME}.tgz"
        if [[ -d "${HOME_DIR}" ]]
        then
            echo "Archiving ${HOME_DIR} to ${ARCHIVE_FILE}."
            tar -zcf ${ARCHIVE_FILE} ${HOME_DIR} &> /dev/null
            if [[ "${?}" -ne 0 ]]
            then
                echo "Could not create ${ARCHIVE_FILE}." >&2
                exit 1
            fi
        else
            echo "${HOME_DIR} does not exist." >&2
            exit 1
        fi
    fi

    if [[ "${DELETE_USER}" = 'true' ]]
    then
        userdel ${REMOVE_OPTION} ${USERNAME}
    
        if [[ "${?}" -ne 0 ]]
        then
            echo "The account ${USERNAME} was not deleted." >&2
            exit 1
        fi
        echo "The account ${USERNAME} was deleted."
    else
        chage -E 0 ${USERNAME}

        if [[ "${?} -ne 0 " ]]
        then
            echo "The account ${USERNAME} was not disabled." >&2
            exit 1
        fi
        echo "The account ${USERNAME} was disabled."
    fi
done

exit 0

