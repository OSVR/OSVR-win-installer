# OSVR-win-installer
Windows installer for OSVR server application
Installer script built with NSIS.

## NSIS script: setup.nsi##

- Uses the following plugins
	- LogEx.dll
	- nsProcess.dll
	- newadvsplash.dll
	- SimpleSC.dll
	- AccessControl.dll

## Requirements for running the script:##
-	Name of the script is: setup.nsi
-	Desired distribution must go in a directory called “distro” in a directory parallel to the script directory
-	Uses registry value to determine if installed version is newer or older than version contained in the installer
- The following items must be in the script directory
	- splash.bmp
	- osvr_server.ico
	- license.txt (Apache 2.0 license)

## Installer capabilities: ##
- checks for free drive space before installing
- checks that installed version is less than the version about to be installed
- logs messages with timestamps to diagnose installer/uninstaller issues
- uses osvr.ico for start menu and uninstaller entry in the control panel
- uninstall shows up in the control panel
- deletes all OSVR files upon uninstall
- cleans up registry upon uninstall
- stops osvr_server.exe before uninstalling or updating without user intervention
- install and uninstall do not require restart
- starts osvr_server.exe after installer completes
- starts osvr_server.exe upon login for all users
- read version number from osvr_server.exe in the distribution
- read distro install size from distribution to use to check for available disk space
- installs a registry key to facilitate plugin installations: HKLM/Software/OSVR/installationDirectory
- installs an environment variable to facilitate plugin installations: OSVR\_INSTALL_DIR

## Improvements: ##
- osvr_server.exe needs to be converted into a service
- buildInstaller.bat and script should be modified to take runtime variable to point to the to-be-installed distribution directory rather than relying on a fixed location