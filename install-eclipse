#!/bin/bash
# --------------------------------------------------------------------
#
# install-eclipse - non-interactive eclipse installer
#
# --------------------------------------------------------------------
# AUTHOR:   Copyright (C) Budhaditya Das <budhash@gmail.com>
# VERSION:  1.4
# --------------------------------------------------------------------
# DESCRIPTION:
#
# install-eclipse installs eclipse via command line. Optionally, it can 
# install eclipse plugins as well
# --------------------------------------------------------------------
# LICENSE:
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
# --------------------------------------------------------------------
# USAGE:
#
# Type "install-eclipse -h" for usage guidelines.
# --------------------------------------------------------------------

## begin ## meta-data
readonly __APPNAME=$( basename "${BASH_SOURCE[0]}" )
readonly __APPVERSION=1.4
readonly __SUPPORTED_OS=(MAC LINUX-DEBIAN)
readonly __SUPPORTED_ARCH=(x86_64 x86)
readonly __DEBUG=FALSE
readonly __CREATENEWLOG=TRUE
## end ## meta-data

## begin ## common helper functions

##
# @info     logging functions
##
function _log() { echo "[info]: $@" 1>&2; }
function _warn() { echo "[warn]: $@" 1>&2; }
function _error() { echo "[error]: $@" 1>&2; }
function _error_exit() { echo "[error]: $@" 1>&2; exit 1;}
function _debug() { [ "$__DEBUG" == "TRUE" ] && echo "[debug]: $@" 1>&2; }

##
# @info     string functions
##
function _trimall() { echo $(echo "$@" | tr -d '[ \t]' | tr 'A-Z' 'a-z'); }
function _lowercase() { echo "$@" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"; }
function _uppercase() { echo "$@" | sed "y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/"; }

##
# @info     returns the current os enum [WINDOWS/MAC/LINUX]
# @param    na
# @return   os enum [WINDOWS , MAC , LINUX]
##
function _get_os()
{
    local _ossig=`uname -s 2> /dev/null | tr "[:upper:]" "[:lower:]" 2> /dev/null`
    local _os_base="UNKNOWN"
    case "$_ossig" in
        *windowsnt*)_os_base="WINDOWS";;
        *darwin*)   _os_base="MAC";;
        *linux*)    
                    if [ -f /etc/redhat-release ] ; then
                        _os_base="LINUX-REDHAT"
                    elif [ -f /etc/SuSE-release ] ; then
                        _os_base="LINUX-SUSE"
                    elif [ -f /etc/mandrake-release ] ; then
                        _os_base="LINUX-MANDRAKE"
                    elif [ -f /etc/debian_version ] ; then
                        _os_base="LINUX-DEBIAN"             
                    else
                        _os_base="LINUX"            
                    fi
            ;;
        *)          _os_base="UNKNOWN";;
    esac
    echo $_os_base
}

##
# @info     returns the current cpu architure
# @param    na
# @return   cpu architure [x86_64 , x86]
##
function _get_arch(){
    local _arch="UNKNOWN"
    case "$(_get_os)" in
        WINDOWS)  _arch=`uname -p 2> /dev/null`;;
        MAC)      [ "$(sysctl hw.cpu64bit_capable | awk '{print $2}')" == "1" ] && _arch=x86_64 || _arch=x86;;
        LINUX*)    _arch=`uname -m 2> /dev/null`;;
        *)        _arch="UNKNOWN";;
    esac
    echo $_arch         
}

##
# @info     creates and returns a temporary directory
# @param    na
# @return   temporary directory path
##
function _get_tempdir(){
    [[ -z "$1" ]] && local _prefix=bytemp || local _prefix=$1
    _debug "creating temporary directory.."
    
    if [ ! -d "$_tmpdir" ]; then
        # Sets $TMPDIR to "/tmp" only if it didn't have a value previously
        local _tmpdir=`mktemp -d ${_tmpdir:-/tmp}/${_prefix}.XXXXXXXXXX` || { _error_exit 'cannot create a temporary directory';}
    fi

    #populate the global array with all the temp dirs that are created
    _exists=false
    for p in "${__TMPDIRS[@]}"; do [ "$p" == "$_tmpdir" ] && _exists=true && break; done; 
    [ ! "$_exists" == "true" ] && __TMPDIRS=("${__TMPDIRS[@]}" $_tmpdir)

    echo "$_tmpdir"
}

##
# @info     returns the http response code for the given url
# @param    url
# @param    destination folder
# @return   temporary directory path
##
function _get_responsecode(){
	if _cmd="$(type -p curl)" || ! [ -z "$_cmd" ]; then
	    echo --url "$1" | curl -ILs --config - -w "%{http_code}\\n" -o /dev/null
	elif _cmd="$(type -p wget)" || ! [ -z "$_cmd" ]; then
		wget -S "$1" 2>&1 | grep "HTTP/" | awk '{print $2}'  
	fi 
}

##
# @info     print the html contents of the url to standard output
# @param    url
# @return   html content
##
function _get_url(){
	local _cmd=
	if _cmd="$(type -p curl)" || ! [ -z "$_cmd" ]; then
	    curl -s "$1"
	elif _cmd="$(type -p wget)" || ! [ -z "$_cmd" ]; then
	    wget -qO- "$1"	  
	fi
}

##
# @info     downloads and extracts a compressed archive
# @param    download url
# @param    destination folder
# @return   temporary directory path
##
function _download_extract(){
    [[ -z "$1" ]] && _error_exit "download not specified" || local _dnld_url=$1
    [[ -z "$2" ]] && _error_exit "destination directory not specified" || local _dest_dir=$2
    local _has_sub_dir=$3
    
    #check to see if the download file exists
    [ "$(_get_responsecode $_dnld_url)" == "200" ] || _error_exit "file [$_dnld_url] doesn't exist!"
    
    local _file=$(basename $_dnld_url)
    local _filename="${_file%.*}"
    local _ext="${_file##*.}"
    
    #check to see if the extension ends in tar.gz
    if [ "$_ext" == "gz" ] && [ "${_filename##*.}" == "tar" ]; then
        _ext="${_filename##*.}".$_ext
        _filename="${_filename%.*}"
    fi  
    
    #create a temporary directory
    local _tmpdir=$(_get_tempdir)
    #trap "{ echo \"clearing temporary directory\"; rm -rf ${_tmpdir}; exit 255; }" SIGINT

    case $_ext in
        tar.gz)
                _debug "downoading [from $_dnld_url] and extracting [to $_dest_dir]"
                _get_url $_dnld_url | tar -xvz -C "$_tmpdir" > /dev/null 2>&1
                ;;
             *) _error_exit "unsupported extension type [$_ext]"
     esac

    if [ "$_has_sub_dir" == "false" ]; then
         mv "$_tmpdir" "$_dest_dir"
    else
		local _sub_dir=$(ls -t $_tmpdir | head -1)
        if [ -d "$_tmpdir/$_sub_dir" ]; then
            mv "$_tmpdir/$_sub_dir" "$_dest_dir"
            rm -rf "$_tmpdir"
        else
            rm -rf "$_tmpdir"
            _error_exit "sub-directory [$_sub_dir] not found in downloaded archive"
        fi          
    fi
}

## end ## common helper functions

##
# @info     bootstraping function, loads various system variables like [__OS , __ARCH , __BASEDIR ]
#           and checks that the script can be executed on teh current os
# @param    na
# @return   na
##
function _bootstrap(){
    #setup root directory variable
    readonly __BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    readonly __CFGFILE="$( basename "${BASH_SOURCE[0]}" )".ini
    readonly __LOGFILE=./"$( basename "${BASH_SOURCE[0]}" )".log
    if [ -f "$__LOGFILE" ] && [ "$__CREATENEWLOG" == "TRUE" ]; then 
        rm -rf "$__LOGFILE"
    else
        echo "----------------------------------" >> "$__LOGFILE"
        echo "`date`" >> "$__LOGFILE"
        echo "----------------------------------" >> "$__LOGFILE"
    fi  
    
    #detect os and populate the __OS variable
    readonly __OS=$(_get_os)
    _supported=false
    for a in "${__SUPPORTED_OS[@]}"; do [[ "$a" == "$__OS" ]] && _supported=true; done
    [ "$_supported" != "true" ] && _error_exit "script doesn't support current operating system. supported : $__SUPPORTED_OS"
    
    #detect architecture and populate the __ARCH variable
    readonly __ARCH=$(_get_arch)
    _supported=false
    for a in "${__SUPPORTED_ARCH[@]}"; do [[ "$a" == "$__ARCH" ]] && _supported=true; done
    [ "$_supported" != "true" ] && _error_exit "script doesn't support current architecture. supported : $__SUPPORTED_ARCH"
}

##
# @info     cleanup at the end of execution
# @param    na
# @return   na
##
function _cleanup(){
    _log "cleaning up"
    for d in "${__TMPDIRS[@]}"; do  
        echo rm -rf "${d}"  
    done;
}

##
# @info     main function
# @param    na
# @return   na
##
function _main(){
    _bootstrap
    _load_config

    local _force_install=false
    local _plugins_only=false
    local _optimize_install=false
    local _plugin_config=
    local _plugin_name=
    local _download_url=
    
    while getopts "hfnop:c:d:" OPTION
    do
         case $OPTION in
             h) _usage; exit 0;;
             n) _plugins_only=true;;
             f) _force_install=true;;
             o) _optimize_install=true;;
             c) _plugin_config=$OPTARG;;
             d) _download_url=$OPTARG;;
             p) 
                _plugin_name=$OPTARG
                _exists=false
                for p in "${_plugins[@]}"; do [ "$p" == "$_plugin_name" ] && _exists=true && break; done; 
                [ ! "$_exists" == "true" ] && _plugins=("${_plugins[@]}" $_plugin_name)
                ;;
             ?) _usage error;;
         esac
    done
    shift $((OPTIND-1)) 
	
    [[ -z "$1" ]] && _error_exit "install folder not specified" || local _install_dir=$1
          
	#handle os specific folder structures
	case "$__OS" in
        MAC) 
			if ! [[ "$_install_dir" == *.app ]];then
				_install_dir=${_install_dir}.app
			fi	
    esac

    if [ "$_plugins_only" == "false" ]; then
        if [ -d $_install_dir ]; then
            if [ "$_force_install" == "true" ]; then 
                _log "removing existing folder [$_install_dir]"
                rm -rf "$_install_dir"
            else    
                _error_exit "install folder already exists"
            fi  
        fi
        
        #installing
        install_application "$_install_dir" "$_download_url"
        
		#workaround for legacy installs on osx
		if [[ "$_install_dir" == *.app ]] && [ -f "$_install_dir"/Eclipse.app/Contents/MacOS/eclipse ]; then
			_install_dir=${_install_dir%.app}
			mv ${_install_dir}.app $_install_dir
		fi	
		
        #optimizing installation 
        if [ "$_optimize_install" == "true" ]; then
            optimize_install "${_install_dir}"
        fi
    fi

    #installing plugins - passed via command line
    if [ "$_plugin_name" != "" ]; then
        [ $(which java | grep -c 'java') -eq 0 ] && _error_exit "java not installed. unable to install plugins"
        for p in "${_plugins[@]}"; do  
            install_plugin "${_install_dir}" "${p}" 
        done;
    fi
    
    #installing plugins - passed via config file
    if [ "$_plugin_config" != "" ]; then
        [ $(which java | grep -c 'java') -eq 0 ] && _error_exit "java not installed. unable to install plugins"
        #[ ! -f "$_install_dir"/eclipse ] && _error_exit "valid eclipse installation directory not found at [$_install_dir]"
        install_plugins "$_plugin_config" "$_install_dir"
    fi
    
    _cleanup        
}

##
# @info     load all common application related variables
# @param    na
# @return   na
##
function _load_config(){
    _ECLIPSE_VERSION=4.6
    _ECLIPSE_DNLD_MIRROR=http://mirror.cc.columbia.edu/pub/software/eclipse/eclipse/downloads
    _ECLIPSE_DOWNLOAD_URL=http://download.eclipse.org/eclipse/downloads/
}

##
# @info     usage information
# @param    na
# @return   na
##
function _usage()
{
    if [ "$1" != "error" ]; then
        echo "$__APPNAME $__APPVERSION, non-interactive eclipse installer"
    fi
    cat << EOF
Usage: $__APPNAME [OPTIONS]... install_folder

Options:
-------
    -h                          
        show this message
        
    -d <download_url>           
        download url to use. if this is not specified, 
        the download url is extracted from download site
        
    -p <"repository,plugin_id">   
        information about plugin to be installed. 
        it should be in the format "repository,plugin_id"
        
    -c <config_file>            
        config file containing plugin information. 
        it should be in the format "repository,plugin_id" per line
        
    -f                          
        force remove existing install_folder, if it exists
        
    -o                      
        optimize the eclipse.ini file [EXPERIMENTAL]

Examples:
--------
    -install latest version without any plugins into "eclipse" folder
    $__APPNAME eclipse
    
    -install eclipse and jdt plugin
    $__APPNAME -p "http://download.eclipse.org/releases/kepler,org.eclipse.jdt.feature.group" eclipse
    
    -install eclipse, jdt plugin and testng plugin
    $__APPNAME -p "http://download.eclipse.org/releases/kepler,org.eclipse.jdt.feature.group" -p "http://beust.com/eclipse/,org.testng.eclipse" eclipse
    
    -install eclipse along with plugins specified in a config file
    $__APPNAME -c ./plugins.cfg eclipse
    
    -install eclipse along with plugins specified in a remote config file
    $__APPNAME -c http://127.0.0.1:8000/plugins.cfg  eclipse
    
    -install plugins specified without instastalling (in an existing installation)
    $__APPNAME -n -c http://127.0.0.1:8000/plugins.cfg eclipse
    
    -install eclipse and remove existing destination folder if it exists
    $__APPNAME -f eclipse
    
    -install eclipse and optimize eclipse.ini file [EXPERIMENTAL]
    $__APPNAME -f -o eclipse
    
    -misc commands
    $__APPNAME -o -f -c http://myserver/common/plugins/java_plugins.cfg -d http://myserver/common/binaries/eclipse-platform-4.3-macosx-cocoa-x86_64.tar.gz

EOF
    if [ "$1" == "error" ]; then
        exit 1
    fi
}

##
# @info     starts the installation process
# @param    na
# @return   na
##
function install_application(){
    _log "starting installation"
    [[ -z "$1" ]] && local _install_dir=./eclipse || local _install_dir=$1
    local _download_url=$2
    
    [ -d $_install_dir ] && _error_exit "destination folder already exists"
    
    if [ "$_download_url" == "" ] || [ "$_download_url" == "-" ]; then
        _download_url=$(get_download_url $__OS $__ARCH)
        [ "$_download_url" == "" ] && _error_exit "unable to find download url for os=$__OS arch=$__ARCH"
    fi

    _download_extract "$_download_url" "$_install_dir"
}

##
# @info     extracts and returns the download url for given os/architecture
# @param    os enum
# @param    cpu architecture enum
# @return   download url
##
function get_download_url(){
    [[ -z "$1" ]] && _error_exit "os not specified" || local _os=$1
    [ -z $2 ] && _error_exit "arch not specified" || local _arch=$2
    local _tmp_url_a=$(_get_url $_ECLIPSE_DOWNLOAD_URL | grep -A1 "Latest Release" | grep -Eo "drop.*/\"" | awk -F\" '{print $1}')
    local _dnld_url=
    
    case "$_os" in
        MAC) 
            local _tmp_url_b=$(_get_url $_ECLIPSE_DOWNLOAD_URL$_tmp_url_a | grep eclipse-platform | grep `_lowercase $_os` | grep $_arch | awk -F"href=\"download.php" '{print $2}' | awk -F\" '{print $1}' | awk -F= '{print $2}')
            #echo http://www.eclipse.org/downloads/download.php?file=/eclipse/downloads/drops4/R-4.3-201306052000/eclipse-platform-4.3-macosx-cocoa-x86_64.tar.gz\&mirror_id=454
            _dnld_url="$_ECLIPSE_DNLD_MIRROR/${_tmp_url_a}${_tmp_url_b}"
            ;;
        LINUX*)
            local _tmp_url_b=$(_get_url $_ECLIPSE_DOWNLOAD_URL$_tmp_url_a | grep eclipse-platform | grep linux | grep $_arch | awk -F"href=\"download.php" '{print $2}' | awk -F\" '{print $1}' | awk -F= '{print $2}')
            #http://download.eclipse.org/eclipse/downloads/drops4/R-4.3-201306052000/download.php?dropFile=eclipse-SDK-4.3-linux-gtk-x86_64.tar.gz
            _dnld_url="$_ECLIPSE_DNLD_MIRROR/${_tmp_url_a}${_tmp_url_b}"
            ;;
        *) _error_exit "unsupported os/architecture";;
    esac

    _log "extracted download url [$_dnld_url]"
    echo "$_dnld_url"
}

##
# @info     returns the current cpu architure
# @param    na
# @param    installation directory
# @param    config file containing plugin details
# @return   na
##
function optimize_install(){
    _log "optimizing installation"
    #[[ -z "$1" ]] && _error_exit "os not specified" || local _os=$1
    [[ -z "$1" ]] && _error_exit "installation directory not specified" || local _install_dir=$1
    local _eclipse_ini=
    
    case "$__OS" in
        MAC) 
			if [ -f "$_install_dir"/Contents/MacOS/eclipse ]; then
				_eclipse_ini="$_install_dir"/Contents/MacOS/eclipse.ini
			else
				_eclipse_ini="$_install_dir"/Eclipse.app/Contents/MacOS/eclipse.ini	
			fi
			;;
        LINUX*) _eclipse_ini="$_install_dir/eclipse.ini" ;;
        *)      _error_exit "unsupported os/architecture";;
    esac

    [ -f "$_eclipse_ini" ] || _error_exit "eclipse.ini file not found at [$_eclipse_ini]"
    
    if [ ! -f "$_eclipse_ini.orig" ]; then
        _debug "backing up existing eclipse.ini to eclipse.ini.orig"
        cp "$_eclipse_ini" "${_eclipse_ini}".orig
    fi
    
    echo -Xverify:none >> "$_eclipse_ini"
    echo -Xincgc >> "$_eclipse_ini"
    echo -Xss4m >> "$_eclipse_ini"
    echo -Xms128m >> "$_eclipse_ini"
    echo -Xmx1024m >> "$_eclipse_ini"
    echo -XX:PermSize=256m >> "$_eclipse_ini"
    echo -XX:MaxPermSize=512m >> "$_eclipse_ini"
    echo -XX:MaxGCPauseMillis=10 >> "$_eclipse_ini"
    echo -XX:MaxHeapFreeRatio=70 >> "$_eclipse_ini"
    echo -XX:+UseConcMarkSweepGC >> "$_eclipse_ini"
    echo -XX:+CMSIncrementalMode >> "$_eclipse_ini"
    echo -XX:+CMSIncrementalPacing >> "$_eclipse_ini"
    echo -XX:+UseFastAccessorMethods >> "$_eclipse_ini"
    echo -XX:+UseFastAccessorMethods >> "$_eclipse_ini"
    echo -XX:+UnlockExperimentalVMOptions >> "$_eclipse_ini"
    echo -XX:+AggressiveOpts >> "$_eclipse_ini"
    echo -XX:+DoEscapeAnalysis >> "$_eclipse_ini"
    echo -XX:+UseCompressedOops >> "$_eclipse_ini"
    echo -XX:+ExplicitGCInvokesConcurrentAndUnloadsClasses >> "$_eclipse_ini"
}

##
# @info     installs plugins(s) specified in a configuration file
# @param    na
# @param    installation directory
# @param    config file containing plugin details
# @return   na
##
function install_plugins(){
    [[ -z "$1" ]] && _error_exit "plugin config file not specified" || local _plugin_config=$1
    [[ -z "$2" ]] && _error_exit "installation directory not specified" || local _install_dir=$2
    local _cmd=
    if [ $(echo $_plugin_config | grep -Eoc '^(http|https)://.*') -gt 0 ]; then
        #check to see if the download file exists
        [ "$(_get_responsecode $_plugin_config)" == "200" ] || _error_exit "plugin config file not found at [$_plugin_config]"
        _cmd=_get_url
    else
        [ -f "$_plugin_config" ] || _error_exit "plugin config file not found at [$_plugin_config]"
        _cmd=cat
    fi

    _log "installing plugins from [$_plugin_config]"
    
    $_cmd "$_plugin_config" | \
    while read line; do
        install_plugin "$_install_dir" "$line"
    done
    
    #remove temp dir if it exists
    [ -d "$_tmpdir" ] && rm -rf "$_tmpdir"
}

##
# @info     installs the specified plugin
# @param    na
# @param    installation directory
# @param    repository,plugin_id (in a single line)
# @return   na
##
function install_plugin(){
    local _install_dir=$1
    shift 1

    local line="$@" # get all args
    local line=$(echo "$@" | sed 's/^[ \t]*//')
    local first_char=`echo ${line} | awk '{ print substr( $0, 0, 1 ) }'`
    [ "${first_char}" == "#" ] && return 1    
    local _repo=`echo "${line}" | awk -F, '{print $1}'`
    local _plugin=`echo "${line}" | awk -F, '{print $2}'`

    _log "installing plugin: $_plugin"

	#handle os specific folder structures
	local _eclipse_exec="$_install_dir"/eclipse
	if [ -f "$_install_dir"/Contents/MacOS/eclipse ]; then
		_eclipse_exec="$_install_dir"/Contents/MacOS/eclipse
	fi

    local _success=$($_eclipse_exec -nosplash -application org.eclipse.equinox.p2.director -repository "$_repo" -installIU "$_plugin" 2>>$__LOGFILE | grep -Eoc '^Operation completed in')
    [ $_success -eq 0 ] && _error "plugin [$_plugin] installation failed. see [$__LOGFILE] for more details"
}

#trap _cleanup 1 2 3 4 6 8 10 12 13 15
_main $@
exit 0
