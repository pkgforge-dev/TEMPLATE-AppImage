################################################################################

MSG_HELP="
Usage:

$ setup [FLAGS]

Available flags/arguments

--install
	Integrates the AppImage with your system
	By default it will try to do the following tasks:
	- Create symlinks that lead to the appimage
	- Copy a configuration to your home directory
	- Create a dot DESKTOP application file that will run the appimage

--no-links
	Will not create symlinks that go from /usr/bin/ to the AppImage

--no-config
	Will not copy the recommended config during the installation

--no-desktop
	Will not create/update the application desktop file and its icon

--force
	Overwrites in case that there are files or paths that already exist
	In the specific case of the program's config, a backup will be made locally before copying it and if a backup already exists, it will be wiped first

Some examples:

$ setup --install
Integrates the appimage to our system

$ setup --install --force
Updates symlinks in case they already exist

$ setup --install --no-links
Creates the DESKTOP file only
When the script is unable to create the symlinks, the DESKTOP file will be made to run the appimage directly instead of running it through the symlinks
"

MSG_ERR="[ ERR ]"
MSG_NOT="[ ! ]"
MSG_USE_FORCE="Run again with --force"

INSTALL=0
COPY_CONFIG=1
MAKE_LINKS=1
MAKE_DESKTOP=1
OVERWRITE=0
declare -a ARGUMENTS=(
	"--install"
	"--no-config"
	"--no-links"
	"--no-desktop"
	"--force"
)

echo "
	SETUP SCRIPT
"

for FLAG in $@
do

	DET=0

	if [ "$FLAG" == "--install" ]
	then
		DET=1
		INSTALL=1
	fi

	if [ "$FLAG" == "--no-config" ]
	then
		DET=1
		COPY_CONFIG=0
	fi

	if [ "$FLAG" == "--no-links" ]
	then
		DET=1
		MAKE_LINKS=0
	fi

	if [ "$FLAG" == "--no-desktop" ]
	then
		DET=1
		MAKE_DESKTOP=0
	fi

	if [ "$FLAG" == "--force" ]
	then
		DET=1
		OVERWRITE=1
	fi

	if [ $DET -eq 1 ]
	then
		echo "$MSG_NOT Detected flag: $FLAG"
	fi
done

echo "
$MSG_NOT AppImage path: $(realpath -e "$URUNTIME")
$MSG_NOT Mounted path: $(realpath -e "$APPDIR")
"

if ! [ $INSTALL -eq 1 ]
then
	echo "$MSG_HELP"
	exit 0
fi

# Create symlinks

if [ $MAKE_LINKS -eq 1 ]
then

	WARNED=0

	for BIN_LINK in "${LBINARIES[@]}"
	do

		if [ -f "$BIN_LINK" ] || [ -d "$BIN_LINK" ]
		then

			ls -l "$BIN_LINK"
			if [ $OVERWRITE -eq 0 ]
			then
				MAKE_LINKS=0
				echo "$MSG_ERR Path already exists. $MSG_USE_FORCE"
				break
			fi

		fi

		ln -vsf "$URUNTIME" "$BIN_LINK"

	done

fi

# Copy desktop file and icon

if [ $MAKE_DESKTOP -eq 1 ]
then

	# Icon

	OK=0
	mkdir -vp "$(dirname "$PATH_ICON")"
	if [ -f "$PATH_ICON" ] || [ -d "$PATH_ICON" ]
	then
		ls -l "$PATH_ICON"
		if [ $OVERWRITE -eq 1 ]
		then
			OK=1
		else
			echo "$MSG_ERR Failed to copy icon. $MSG_USE_FORCE"
		fi
	else
		OK=1
	fi
	if [ $OK -eq 1 ]
	then
		cp -va "$APPDIR"/.DirIcon "$PATH_ICON"
	fi

	# Desktop file

	OK=0
	DESKTOP_OK="/usr/share/applications/""$DESKTOP"
	mkdir -vp "$(dirname "$DESKTOP_OK")"
	if [ -f "$DESKTOP_OK" ] || [ -d "$DESKTOP_OK" ]
	then
		ls -l "$DESKTOP_OK"
		if [ $OVERWRITE -eq 1 ]
		then
			OK=1
		else
			echo "$MSG_ERR Failed to copy DESKTOP file. $MSG_USE_FORCE"
		fi
	else
		OK=1
	fi
	if [ $OK -eq 1 ]
	then
		cp -va "$APPDIR"/"$DESKTOP" "$DESKTOP_OK"
		chmod +x "$DESKTOP_OK"
	fi

	# Desktop file's Exec

	if [ $OK -eq 1 ]
	then

		if [ $MAKE_LINKS -eq 1 ]
		then

			if ! [ -f "$MAIN_BIN" ]
			then
				MAKE_LINKS=0
			fi

			if [ -f "$MAIN_BIN" ]
			then

				DESTINATION=$(readlink "$MAIN_BIN")
				if ! [ "$DESTINATION" == "$URUNTIME" ]
				then
					MAKE_LINKS=0
				fi

			fi

		fi

		if [ $MAKE_LINKS -eq 0 ]
		then
			sed -i 's:Exec='"$DESKTOP_EXEC"':Exec=\"'"$URUNTIME"'\":' "$DESKTOP_OK"
		fi

	fi

fi

# Config (if the app has one)
if [ $COPY_CONFIG -eq 1 ] && [ -d "$APPDIR"/_config ]
then

	AE=0

	OK=0

	if [ -f "$CONFIG_DIR" ] || [ -d "$CONFIG_DIR" ]
	then

		AE=1

		ls -l "$CONFIG_DIR"

		if [ $OVERWRITE -eq 1 ]
		then
			OK=1
		else
			echo "$MSG_ERR Failed to copy config. $MSG_USE_FORCE"
		fi

	else
		OK=1
	fi

	if [ $OK -eq 1 ]
	then
		if [ $AE -eq 1 ] && [ $OVERWRITE -eq 1 ]
		then
			BACKUP="$CONFIG_DIR".backup
			if [ -e "$BACKUP" ]
			then
				echo "$MSG_NOT DELETING OLD BACKUP..."
				rm -vrf "$BACKUP"
			fi
			echo "$MSG_NOT CREATING A BACKUP OF THE CURRENT CONFIG..."
			mv -v "$CONFIG_DIR" "$CONFIG_DIR".backup
		fi
		mkdir -vp "$CONFIG_DIR"
		cp -va "$APPDIR"/_config/* "$CONFIG_DIR"/

		# RUN EXTRA JOB(s)

		additional_config_tasks

	fi

fi

echo "
All done!"

if [ $MAKE_LINKS -eq 1 ]
then
	echo "$MSG_NOT The following symlinks will now run the appimage:"
	for BIN_LINK in "${LBINARIES[@]}"
	do
		echo "→ $BIN_LINK"
	done
fi

if [ $MAKE_DESKTOP -eq 1 ]
then
	echo "$MSG_NOT Created/updated the application file: $DESKTOP"
	cat /usr/share/applications/"$DESKTOP"|grep "^Exec="
fi

if [ $COPY_CONFIG -eq 1 ]
then
	echo "$MSG_NOT Copied the config"
	find "$CONFIG_DIR"
fi
