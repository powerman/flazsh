# Load initial environment.
IFS=$'\0'
env=($(</proc/$$/environ))
# Use TERM and AUTORUN from initial environment.
typeset -- $env
if [[ $EUID = 0 ]] || [[ $USER = root ]]; then
    unset AUTORUN
fi
if [[ $TERM == rxvt* && -n $AUTORUN ]]; then
    # Start new terminal with initial environment of current one.
    unset chpwd_functions # no mise in $PATH
    cd
    env -i $env urxvtc -name $AUTORUN
elif [[ $TERM == foot* && -n $AUTORUN ]]; then
    # Start new terminal with initial environment of current one.
    env -i $env footclient --app-id="footclient-$AUTORUN" --login-shell --client-environment \
        ${FOOT_SOCKET+--server-socket="$FOOT_SOCKET"} &
fi
