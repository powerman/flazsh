########################################
#		FLAzSH!			
#    Fastest ZSH you've ever seen.	
#					


#---------------------------------------
# ZSH Cool Features                     
#                                       
# cd <old> <new>		# s/<old>/<new>/ в текущем `pwd`
# $PWD				# всегда равен `pwd`
# $path				# работа с $PATH как с массивом
# print -l …			# echo по одному параметру на строку
# ARGV0=… cmd …			# подменить argv[0] в cmd и для ps f
# ${(kv@)var}			# флаги для параметров
# ${var:h}			# модификаторы для параметров
# /*/file.c(:h)			# модификаторы для глобов и аргументов
# /*(/.@*…m-2…Lm+5…omod…^…[1])	# квалификаторы для глобов NOTE БОМБА! фильтры, сортировка, выборка
# /*(D)				# … вкл. GLOB_DOTS для совпадения и с .*
# /*(N)				# … вкл. NULL_GLOB для ничего если нет совпадения
# **/…				# текущий или подкаталог любого уровня вложенности
# (one|two)*			# глоб по альтернативе
# file-1.<4->*			# глоб по числовому интервалу
# =ls				# $(which ls)
# $fg[<color>] и $bg[<color>]	# после autoload colors; colors
# $fg_bold и $fg_no_bold	# плюс $bg_bold и $bg_no_bold
# r=~/proj/rajeev; : ~r		# cd ~r/… плюс показывает ~r/… в PROMPT
# typeset -U path		# в $path только уникальные элементы
# export -TU GOPATH gopath	# связать, сделать уникальными, экспортировать
# vared PATH			# редактирование параметра
# [[ … ]]			# адекватная альтернатива мутным test и [
# (( … ))			# поддерживает float
# $(( [##16_4] 2**32 - 1 ))	# можно задать base, группы, выводить ли base
# bindkey			# настройка/вывод hotkeys
# <Up><Up>…<Ctrl-O><Ctrl-O>…	# повтор последовательности команд из истории
# …<Esc><Enter>			# ввод многострочной последовательности команд
# …<Esc>q			# отложить текущую команду до выполнения новой
# zmv				# альтернатива rename_cb
# $RPROMPT			# дополнение $PROMPT для правой стороны
# <file				# просмотр файла через $READNULLCMD


#---------------------------------------
# Особенности (с текущим набором опций) 
#                                       
# - Не поддерживает /etc/inputrc, поэтому нужны zkbd/bindkey.
# - Имена опций:
#   * Регистр и подчёркивания не важны: autocd / AUTO_CD.
#     В доке AUTO_CD, setopt выводит autocd.
#   * У всех есть префикс no: noautocd, nomatch/nonomatch,
#     но можно вместо setopt с no использовать команду unsetopt.
# - Переменные называет "parameters" пока им не сделан export, после этого
#   они таки копируются в environment variables.
# - Массивы:
#   * Индексируются с 1: ${array[1]}, есть отрицательные индексы с конца.
#   * При обращении как со скаляром - симулирует join q{ }.
#   * При обращении со скаляром как с массивом - возвращает символы строки.
#   * Нельзя сделать export не сменив тип на скаляр.
# - Значение параметра-скаляра передаёт как один аргумент и без кавычек,
#   значение параметра-массива передаёт как список аргументов: cmd $var
# - Пустые значения параметра-скаляра и пустые элементы массива не передаются
#   без явного указания: "$scalar" "${array[@]}" "$@"
# - Двусторонне-связанные переменные с автоматическим split /:/ и join q{:}:
#   $path (параметр типа массив) и $PATH (переменная окружения), $cdpath и
#   $CDPATH, $fpath и $FPATH, etc. Можно делать такие же свои через typeset -T.
# - Двусторонне-связанные переменные скаляры, напр. $PS1 и $PROMPT.
# - Для загрузки и вызова функций используется: autoload <fn>; <fn>
#   * при вызове несуществующей <fn> файл с именем <fn> ищется по всему $fpath
#   * если найден то он загружается как при source
#   * если в нём нет кода кроме объявления одной функции <fn> то она
#     вызывается автоматически
#   * если в нём вообще не объявлена функция <fn> то содержимое всего
#     файла становится функцией <fn>
#   * если в нём есть и <fn> и другой код, то обычно в конце файла нужно
#     явно вызвать <fn> "$@" чтобы она выполнилась и при первом вызове
# - Вложенные функции определяются в момент вызова внешней и становятся
#   глобальными, они даже могут подменить внешнюю для последующих вызовов.
# - setopt localoptions … в функции позволяет изменить опции только в ней
# - emulate -LR zsh в функции позволяет сбросить все опции в исходное и
#   одновременно делает все изменения локальными для функции
# - Два варианта перехвата сигналов: trap '<code>' INT и TRAPINT(){ <code> }
# - Псевдо-сигналы: EXIT (аналог defer), ZERR и DEBUG.
# - В тестах [[ … ]]:
#   * не нужно особым образом учитывать что параметр может быть пустым
#   * можно использовать сравнение с glob-шаблоном: [[ $var = prefix* ]]
#   * можно использовать && || ! (…)
# - Можно использовать (( … )) для арифметических тестов вместо [[ … ]],
#   чтобы для сравнения чисел не использовать текстовые -eq, -lt, etc.
# - Соглашения:
#   * имена параметров-скаляров $БОЛЬШИЕ, параметров-массивов $маленькие


#---------------------------------------
# Global Parameters and Configuration	
#					
# - Переменные окружения и параметры, которые должны быть установлены до
#   запуска любой команды/плагина, т.к. они могут повлиять на их работу.
#   Если какой-то плагин их изменит нежелательным образом - нужно вернуть
#   исходное значение сразу после загрузки этого плагина.
# - Настройки плагинов, которые необходимо установить перед их загрузкой.
GOPATH=$(go env GOPATH 2>/dev/null || echo ~/go)
typeset -U path
if [[ $EUID = 0 ]] || [[ $USER = root ]]; then
	path=(
		~/.local/bin
		$path
	)
else
	path=(
		~/.local/bin
		/mnt/storage/games/bin/
		$path
		$GOPATH/bin
		~/perl5/bin/
		~/node_modules/.bin/
		~/.gem/ruby/*/bin(N[-1])	# корректнее, но медленнее: $(gem env gemdir)/bin
	)
	export INFERNO_HOME=~/inferno/
	# Вывод: perl -I ~/perl5/lib/perl5/ -Mlocal::lib
	export PERL_MB_OPT="--install_base $HOME/perl5"
	export PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"
	# source ~/perl5/perlbrew/etc/bashrc
	# export ANSIBLE_INVENTORY=~/ansible/hosts
fi

optional=(
    ~/.local/bin/git-subrepo/.rc
    ~/.secret.sh
)
for f in $optional; test -e "$f" && source "$f"

export BROWSER=xdg-open
export GPG_TTY=$TTY
export QT_SELECT='qt5'
test -f ~/.config/ripgreprc && export RIPGREP_CONFIG_PATH=~/.config/ripgreprc
eval "$(dircolors -b ~/.dir_colors(N))"

export ECHANGELOG_USER='Alex Efros (powerman) <powerman-asdf@ya.ru>'
export NARADA_USER='Alex Efros <powerman@powerman.name>'
export PERLDOC='-otext'
export TEST_AUTHOR=1
export GO_TEST_COLOR=1
export LESS='-R -M --shift 5 -S'
[[ $EMU == -c* || $EMU == *\ -c* ]] || EMU+=' -c1'

ZSH_CACHE_DIR=${XDG_CACHE_HOME:-~/.cache}/zsh
ZSH_DATA_DIR=${XDG_DATA_HOME:-~/.local/share}/zsh
[[ -d $ZSH_CACHE_DIR ]] || mkdir -p $ZSH_CACHE_DIR
[[ -d $ZSH_DATA_DIR  ]] || mkdir -p $ZSH_DATA_DIR

# zstyle ':prezto:module:prompt' theme 'agnoster'


#---------------------------------------
# Load plugins				
#					
# - До загрузки функций/плагинов нужно настроить $FPATH.
#   В нём должны быть каталоги с функциями для autoload и настройками
#   completions (файлы "_*").
# - После настройки $FPATH, но до загрузки плагинов нужно:
#   * Установить основной keymap (чтобы bindkey плагинов менял его).
#   * Загрузить стандартные модули (zmodload) и функции (autoload),
#     которые могут использоваться плагинами.
#   * Инициализировать стандартные функции: compinit, etc.
#   * Добавить виджеты ZLE (чтобы плагины могли их wrap-ать).
# - Загрузить плагины (порядок может быть важен).
#   * Компенсировать нежелательные изменения переменных окружения.
# - Для ускорения запуска zsh стоит откомпилировать загружаемые файлы.
BUNDLE=$ZDOTDIR/bundle
OMZ=$BUNDLE/oh-my-zsh/plugins
PREZTO=$BUNDLE/prezto/modules

fpath=(
	$ZDOTDIR/functions
	$ZDOTDIR/completions
	$OMZ/cpanm
	$OMZ/docker-machine
	# $PREZTO/prompt/functions
	$BUNDLE/zsh-completions/src
	$fpath
)

autoload -Uz $ZDOTDIR/functions/*(:t)

bindkey -e				# main keymap: emacs

zmodload zsh/complist			# нужен для bindkey -M menuselect
autoload -Uz compinit
compinit -d $ZSH_CACHE_DIR/zcompdump
zzcompile $ZSH_CACHE_DIR/zcompdump

autoload -Uz colors			# нужен для prompt и других
colors					# BUG $bg_bold выдаёт фигню

autoload -Uz promptinit			# темы prompt
promptinit

autoload -Uz bracketed-paste-magic
zle -N bracketed-paste{,-magic}		# разрешить url-quote-magic etc. при paste

autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic	# авто-экранирование при наборе url

autoload -Uz {up,down}-line-or-beginning-search
zle -N up-line-or-beginning-search	# поиск в истории подстроки до курсора
zle -N down-line-or-beginning-search

autoload -Uz edit-command-line
zle -N edit-command-line		# редактирование текущей команды в $EDITOR

autoload -Uz zcalc-auto-insert
zle -N zcalc-auto-insert		# автовставка "ans" перед знаком в zcalc

function expand-or-complete-with-indicator() {
    print -Pn "%{%F{red}…%f%}"
    zle expand-or-complete
    local exit_status=$?
    zle redisplay
    return $exit_status
}
zle -N expand-or-complete-with-indicator

source /usr/lib*/mc/mc.sh		# allow mc to chdir to its latest working dir at exit
zsource $OMZ/../lib/git.zsh		# нужно для тем OMZ и моей
zsource $OMZ/../lib/spectrum.zsh	# more cool colors
zsource $OMZ/../lib/termsupport.zsh	# update term/screen title
zsource $OMZ/dircycle/*.plugin.zsh	# Ctrl-Shift-Left|Right to navigate on pushd stack
# zsource $PREZTO/prompt/init.zsh

# Нужно загружать после добавления всех виджетов ZLE.
zsource $BUNDLE/fast-syntax-highlighting/*.plugin.zsh

# Ускорение загрузки остальных файлов.
zzcompile $ZDOTDIR/.zshrc
zzcompile $BUNDLE/fast-syntax-highlighting/fast-highlight


#---------------------------------------
# ZSH Parameters and Options		
#					
unsetopt BG_NICE			# запускать фоновые задачи без nice
unsetopt CORRECT			# без коррекции для команд
unsetopt FLOW_CONTROL			# Ctrl-S/Ctrl-Q обычные при вводе команды
unsetopt LIST_AMBIGUOUS			# выводить варианты дополнения сразу
unsetopt MULTIOS			# перенаправления fd
unsetopt NOTIFY				# выводить статус фоновых перед prompt
setopt AUTO_CD				# набирать имя каталога без cd
setopt AUTO_PUSHD			# cd работает как pushd, нужен $DIRSTACKSIZE
setopt BSD_ECHO				# не обрабатывать escape sequence в echo без -e
setopt COMBINING_CHARS			# выводить "и" плюс " ̆" как "й"
setopt EXTENDED_HISTORY			# сохранять дату и продолжительность команд
setopt GLOB_STAR_SHORT			# ** работает как **/*
setopt HIST_FIND_NO_DUPS		# не показывать одинаковые команды по Ctrl-R
setopt HIST_IGNORE_DUPS			# не сохранять дубликат предыдущей команды
setopt HIST_IGNORE_SPACE		# не сохранять если перед командой пробел
setopt HIST_NO_STORE			# не сохранять команды fc и history в истории
setopt HIST_SUBST_PATTERN		# использовать шаблоны в модификаторе :s/…/…/
setopt HIST_VERIFY			# показывать подстановку !!… до выполнения
setopt INTERACTIVE_COMMENTS		# комментарии после "#" в командной строке
setopt LONG_LIST_JOBS			# показывать PID при завершении job
setopt MAGIC_EQUAL_SUBST		# поддержка ~… и file completion после = в аргументах
setopt NUMERIC_GLOB_SORT		# глобы файлов с цифрами сортировать как числа
setopt PROMPT_SUBST			# $(…) в $PS1 etc.
setopt PUSHD_IGNORE_DUPS		# не дублировать каталоги в стеке
setopt RC_QUOTES			# экранирование ' дублированием: 'quo''te'
setopt SHARE_HISTORY			# общая история всех zsh с этим $HISTFILE
setopt TRANSIENT_RPROMPT		# RPROMPT только последний, для упрощения copy&paste

ttyctl -f				# не портить терминал; дополнительно: https://habrahabr.ru/post/272581/#term-reset

zstyle ':completion:*:*:*:*:*'                  menu            select
zstyle ':completion:*'				list-colors	"${(s.:.)LS_COLORS}"
zstyle ':completion:*:*:kill:*:processes'	list-colors	'=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
zstyle ':completion:*:*:*:*:processes'		command		'/bin/ps -u $USER -o pid,user,command -w -w'
# Зачем-то "disable named-directories autocompletion".
zstyle ':completion:*:cd:*'			tag-order	local-directories directory-stack path-directories
# Complete . and .. special directories.
zstyle ':completion:*'                          special-dirs    true
# Use caching so that commands like apt and dpkg complete are usable.
zstyle ':completion:*'		                use-cache	yes
zstyle ':completion:*'		                cache-path	$ZSH_CACHE_DIR
# Don't complete uninteresting users…
zstyle ':completion:*:*:*:users'		ignored-patterns \
	adm alertmanager alias amanda apache at avahi avahi-autoipd \
	beaglidx bin cacti canna clamav cmd5checkpw consul cron daemon \
	dbus dhcp distcache dnscache dnslog dnsmasq dovecot dovenull fax \
	fetchmail ftp games gdm geoclue gkrellmd gopher grafana hacluster \
	haldaemon halt hsqldb i2p ident jabber junkbust kdm ldap log lp \
	mail mailman mailnull man messagebus milter mldonkey mysql nagios \
	named netdump news nfsnobody nginx ngrep nobody node_exporter nscd \
	ntp nut nx obsrun opendkim openvpn operator pcap polkitd portage \
	postfix postgres postgrey postmaster privoxy prometheus \
	prometheus-exporter prometheus-node_exporter pulse pushgateway pvm \
	qemu qmaild qmaill qmailp qmailq qmailr qmails quagga radvd rpc \
	rpcuser rpm rtkit scard shutdown squid sshd statd stunnel svn sync \
	tcpdump tftp tinydns usbmux uucp vcsa wwwrun xfs '_*'
# …unless we really want to.
zstyle ':completion:*'				single-ignored	show
# Группы.
zstyle ':completion:*:corrections'	        format		' %F{green}-- %d (errors: %e) --%f'
zstyle ':completion:*:descriptions'	        format		' %F{yellow}-- %d --%f'
zstyle ':completion:*:messages'	                format		' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings'	                format		' %F{red}-- no matches found --%f'
zstyle ':completion:*'		                format		' %F{yellow}-- %d --%f'
zstyle ':completion:*'		                group-name	''
zstyle ':completion:*:-tilde-:*'	        group-order	named-directories path-directories users expand
zstyle ':completion:*:ssh:*'		        group-order	users hosts-domain hosts-host users hosts-ipaddr
zstyle ':completion:*:(scp|rsync):*'	        group-order	users files all-files hosts-domain hosts-host hosts-ipaddr
zstyle ':completion:*:manuals'	                separate-sections	true


# Named directories для сокращённого $PROMPT и cd.
hash -d Go=~/proj/go
hash -d Perl=~/proj/perl
hash -d Rajeev=~/proj/rajeev
hash -d CPDPro=$GOPATH/src/github.com/dentalcpdpro
hash -d MSTrade=~/proj/mstrade
hash -d DF=~/proj/qarea/duefocus
hash -d MTM=$GOPATH/src/github.com/mtgroupit

cdpath=(
	.
	..
	~
	~Go
	~Perl
	~Rajeev
	~CPDPro
	~MSTrade
	~DF
	~MTM
	~/proj/{inferno,js,css,vim,soft}/
	~/proj/allcups
)

HISTFILE=${HISTFILE:#/dev/null}
HISTFILE=${HISTFILE:-$ZSH_DATA_DIR/history${AUTORUN:+.$AUTORUN}}
HISTSIZE=100000
SAVEHIST=$HISTSIZE

DIRSTACKSIZE=20				# ограничить размер стека pushd
READNULLCMD=less			# <file вместо less file
RANDOM=$(print -P "%19<<%D{%s%.}$$")	# seed RNG


#---------------------------------------
# Theme					
#					
palette256

# TIMEFMT=$'\nreal\t%*E\nuser\t%*U\nsys\t%*S'	  # time в стиле bash
TIMEFMT=${(%):-$'\n'"%B%F{$pal[yellow2]}%%*E real%f%b  %F{$pal[green1]}%%*U user%f  %F{$pal[orange1]}%%*S sys%f  %B%%MMB RAM%b"}

# fast-theme powerman

# source $OMZ/../themes/robbyrussell.zsh-theme
# prompt gentoo
prompt powerman


#---------------------------------------
# Key bindings				
#					
autoload -Uz zkbd
[[ ! -f $ZDOTDIR/.zkbd/$TERM-${${DISPLAY:t}:-$VENDOR-$OSTYPE} ]] && zkbd
source	$ZDOTDIR/.zkbd/$TERM-${${DISPLAY:t}:-$VENDOR-$OSTYPE}

zbindkey $key[Tab]		expand-or-complete-with-indicator
zbindkey $key[S-Tab]		reverse-menu-complete
zbindkey $key[Home]		beginning-of-line
zbindkey $key[End]		end-of-line
zbindkey $key[Insert]		overwrite-mode
zbindkey $key[Delete]		delete-char
zbindkey $key[Backspace]	backward-delete-char
zbindkey $key[PageUp]		up-line-or-beginning-search
zbindkey $key[PageDown]		down-line-or-beginning-search
zbindkey $key[Up]		up-line-or-history
zbindkey $key[Down]		down-line-or-history
zbindkey $key[Left]		backward-char
zbindkey $key[Right]		forward-char
zbindkey $key[C-Left]		backward-word
zbindkey $key[C-Right]		forward-word
zbindkey $key[C-Backspace]	backward-delete-word

zbindkey '+'			zcalc-auto-insert	# автоподстановка пред. результата в zcalc
zbindkey '-'			zcalc-auto-insert
zbindkey '*'			zcalc-auto-insert
zbindkey '/'			zcalc-auto-insert
zbindkey -M isearch '+'		self-insert		# компенсация zcalc-auto-insert в -M main
zbindkey -M isearch '-'		self-insert
zbindkey -M isearch '*'		self-insert
zbindkey -M isearch '/'		self-insert
zbindkey -M command '+'		self-insert
zbindkey -M command '-'		self-insert
zbindkey -M command '*'		self-insert
zbindkey -M command '/'		self-insert

zbindkey ' '			magic-space		# history expansion
zbindkey '^Z'			undo			# NOTE отменяет в т.ч. разворачивание Tab-ом
zbindkey '^_'			redo			# Ctrl-/ и Ctrl--
zbindkey '^Q'			push-input		# отложить текущую команду
zbindkey '^[q'			push-input		# use ^[Q to push single line while at PS2
zbindkey '^R'			history-incremental-pattern-search-backward
zbindkey '^S'			history-incremental-pattern-search-forward
zbindkey '^[M'			copy-prev-shell-word	# удобно для переименования файлов
zbindkey '^X^E'			edit-command-line
zbindkey $key[C-PageUp]		insert-cycledright
zbindkey $key[C-PageDown]	insert-cycledleft
zbindkey -M menuselect	$key[C-PageUp]		undo
zbindkey -M menuselect	$key[C-PageDown]	accept-and-infer-next-history
zbindkey -M menuselect	'^O'			accept-and-infer-next-history

# BUG Некоторые иконки (напр.  и ) не вставляются через paste в ZLE.
# Вероятно, проблема в bracketed-paste.


#---------------------------------------
# Functions and Aliases			
#					
alias -s {pdf,gif,png,jpg,mkv,avi,htm,html,doc,odt,xls,ods,odg}='xdg-open'
alias -s {txt,md,adoc,asciidoc}='vi'

alias history='fc -liD'			# показывать время выполнения команд
alias type='type -aS'			# самый короткий и подробный whence/which/where
alias which-command=whence		# запускается по Esc-? (на Alt-? плагин urxvt)

alias run-help &>/dev/null && unalias run-help
autoload -Uz run-help			# запускается по Alt-h
alias help=run-help
autoload -Uz run-help-git
autoload -Uz run-help-ip
autoload -Uz run-help-openssl
autoload -Uz run-help-sudo

autoload -Uz zcalc			# zcalc - замена pcalc для не-perl выражений
alias zcalc='zcalc -f'			# использовать float по умолчанию

autoload -Uz zmv			# zmv 'file(*).txt' 'File${1//-/_}.txt'
alias zcp='zmv -C'
alias zln='zmv -L'
alias mmv='noglob zmv -W'		# mmv file*.txt File*.txt
alias mcp='noglob zmv -W -C'
alias mln='noglob zmv -W -L'

alias bindkey='noglob bindkey'
alias eix='noglob eix'
alias find='noglob find'
alias locate='noglob locate'
alias rsync='noglob rsync'
alias scp='noglob scp'
alias sftp='noglob sftp'

alias ls='ls --color=auto'
alias grep='grep --colour=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn}'
alias egrep='egrep --colour=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn}'
alias fgrep='fgrep --colour=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn}'

alias gh='PAGER= gh'
alias dc='if test -f env.sh; then source env.sh; fi && docker-compose'
alias df='df -kh'
alias emu-g='rlwrap -a -r ~/.local/bin/emu-g'
alias goconvey='goconvey -port=8192 -launchBrowser=false -timeout=20s -excludedDirs=vendor,testdata,bin,service,public,template'
alias lynx='lynx -nopause'
alias mod=~/go/bin/mod # prefer over mono's /usr/bin/mod
alias mysql='mysql --pager="less -XSFe"'
alias reboot='/sbin/runit-init 6'
alias halt='/sbin/runit-init 0'

# if test -f /usr/share/grc/grc.zsh; then
# 	source /usr/share/grc/grc.zsh
# elif test -f /etc/grc.zsh; then
# 	source /etc/grc.zsh
# fi
# unset -f ls
# alias ls='ls --color=auto'  # disable grc because of https://github.com/garabik/grc/issues/144
# unalias make		    # disable grc because of https://github.com/garabik/grc/issues/123

# New commands.
alias -- -='cd -'
alias ...='../..'
alias ....='../../..'
alias .....='../../../..'
alias l="$(whence ls) -l --group-directories-first"
alias la="$(whence ls) -lA --group-directories-first"
alias lt="$(whence ls) -ltr --group-directories-first"
alias lu="$(whence la) -Sr"
alias logc='grc cat'
alias logt='grc tail'
alias mplayerstream='/usr/bin/mplayer -cache 128 -cache-min 50 -playlist'

if [[ $EUID = 0 ]] || [[ $USER = root ]]; then
	if xuser; then
		chpst -u "$XUSER" mkdir -p "$XHOME/.local/share/env"
		function notify-send {
			env USER=$XUSER HOME=$XHOME DISPLAY=$DISPLAY \
				chpst -u $XUSER -e $XHOME/.local/share/env \
				notify-send "$@"
		}
	fi
fi
function notify-remote {
	ssh powerman@powerman.name sudo /etc/sv/notify/actions/notify-send "${(q)@}"
}
[[ $HOST == home ]] && alias alert=alert-local || alias alert=alert-remote


#---------------------------------------
# AutoRun				
#					
unexport AUTORUN
if [[ $EUID = 0 ]] || [[ $USER = root ]]; then
	unset AUTORUN
fi

case $AUTORUN in
(mc)
	env CDPATH=$CDPATH mc -u
	;;
(mutt)
	mutt
	exit
	;;
(rtorrent)
	unset HISTFILE
	sudo -u _torrent killall "rtorrent main" 2>/dev/null
	sudo -u _torrent rtorrent
	;;
(log)
	sudo tail -F /var/log/all/current
	exit
	;;
(root*)
#	sudo -i LD_PRELOAD=$LD_PRELOAD AUTORUN=$AUTORUN
	AUTORUN=$AUTORUN su -w AUTORUN,COLORTERM -
	exit
	;;
(ssh[1])
	ssh -O exit root@${AUTORUN/ssh/srv}
	ssh	    root@${AUTORUN/ssh/srv}
	ping -c 180	 ${AUTORUN/ssh/srv}
	exit
	;;
(ssh3)
	ssh -O exit root@web.powerman.name
	ssh	    root@web.powerman.name
	ping -c 180	 web.powerman.name
	exit
	;;
esac
