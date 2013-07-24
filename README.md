# install-eclipse

## Summary
non-interactive eclipse installer

## Status 
STABLE

## License
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Introduction
install-eclipse is a shell script that installs eclipse in a non-interactive, 
automated way. As part of the workflow, the script install the [Eclipse Platform 
Runtime Binaries](http://www.eclipse.org/downloads/moreinfo/custom.php) and then
installs additional eclipse plugin(s), if specified. 
The list of plugins to be installed can either be a specified via:
* command-line switch. e.g. -p "http://beust.com/eclipse/,org.testng.eclipse"
* local or remote config file, listing the plugins to be installed. 
Refer to [git-java-mvn.cfg](https://github.com/budhash/install-eclipse/blob/master/profiles/git-java-mvn.cfg), as an example.

See Usage and Examples for more details. 

## Features 

* non-interactive eclipse installation, great for automated setups
* installs only what is needed
* ability to provide a list of plugins to be installed. 
* the plugin list can be a remote file accessible over http[s]
* optimizes eclipse.ini [EXPERIMENTAL]

## Installing

    curl -k https://raw.github.com/budhash/install-eclipse/master/install-eclipse > install-eclipse; chmod +x install-eclipse

## Usage

    install-eclipse [OPTIONS]... install_folder

    Options:

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

## Examples
-install latest version into "eclipse" folder. without any additional plugins

    install-eclipse eclipse

-install eclipse and jdt plugin

    install-eclipse -p "http://download.eclipse.org/releases/kepler,org.eclipse.jdt.feature.group" eclipse
    
-install eclipse, jdt plugin and testng plugin

    install-eclipse -p "http://download.eclipse.org/releases/kepler,org.eclipse.jdt.feature.group" -p "http://beust.com/eclipse/,org.testng.eclipse" eclipse
    
-install eclipse along with plugins specified in a config file

    install-eclipse -c ./profiles/plugins.cfg eclipse
    
-install eclipse along with plugins specified in a remote config file

    install-eclipse -c http://127.0.0.1:8000/plugins.cfg  eclipse
    
-install plugins specified without installing (in an existing installation)

    install-eclipse -n -c https://github.com/budhash/install-eclipse/blob/master/profiles/plugins.cfg eclipse
    
-install eclipse and remove existing destination folder if it exists

    install-eclipse -f eclipse
    
-install eclipse and optimize eclipse.ini file [EXPERIMENTAL]

    install-eclipse -f -o eclipse
    
-complex commands

    install-eclipse -o -f -c https://raw.github.com/budhash/install-eclipse/master/profiles/plugins.cfg -d http://mirror.cc.columbia.edu/pub/software/eclipse/eclipse/downloads/drops4/R-4.3-201306052000/eclipse-platform-4.3-macosx-cocoa-x86_64.tar.gz

-install directly without downloading/installing install-eclipse locally 

    bash <( curl -sk https://raw.github.com/budhash/install-eclipse/master/install-eclipse ) -f -c https://raw.github.com/budhash/install-eclipse/master/profiles/git-java-mvn.cfg ./eclipse

## Limitations
* This script has currently been tested on OSX 10.8.3 with Eclipse 4.3 only. 

## Known Issues
* See [install-eclipse issues on GitHub](https://github.com/budhash/install-eclipse/issues) for open issues

## Authors / Contact
budhash (at) gmail

## Download
You can download this project in either [zip](http://github.com/budhash/install-eclipse/zipball/master) or [tar](http://github.com/budhash/install-eclipse/tarball/master) formats.

Or simply clone the project with [Git](http://git-scm.com/) by running:

    git clone git://github.com/budhash/install-eclipse

## Credits / References
* [Installing software using the p2 director application](http://help.eclipse.org/indigo/index.jsp?topic=%2Forg.eclipse.platform.doc.isv%2Freference%2Fmisc%2Fupdate_standalone.html)