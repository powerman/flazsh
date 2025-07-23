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
fi
