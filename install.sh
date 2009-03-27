#!/bin/sh

if [ $(whoami) != "root" ]; then
	echo "This needs to be run as root."
	exit 1;
fi;

REQUIREDAPPS=""
REQUIREDAPPS="${REQUIREDAPPS} hal"
REQUIREDAPPS="${REQUIREDAPPS} mencoder"
REQUIREDAPPS="${REQUIREDAPPS} abcde"
REQUIREDAPPS="${REQUIREDAPPS} id3v2"
REQUIREDAPPS="${REQUIREDAPPS} lame"
REQUIREDAPPS="${REQUIREDAPPS} lsdvd"
REQUIREDAPPS="${REQUIREDAPPS} dvdbackup"

echo "Installing required applications (${REQUIREDAPPS})"
apt-get update
apt-get install ${REQUIREDAPPS}

echo "Looking for possible drives.."
for DRIVE in `ls /dev/scd*`; do
	echo "Found ${DRIVE}":
	cat <<EOF >/usr/share/hal/fdi/policy/20thirdparty/30-diskinserted-${DRIVE##*/}.fdi
<?xml version="1.0" encoding="ISO-8859-1"?>
<deviceinfo version="0.2">
	<device>
		<match key="block.device" string="${DRIVE}">
			<append key="info.callouts.add" type="strlist">diskinserted</append>
		</match>
	</device>
</deviceinfo>
EOF
done;


cp diskinserted "/usr/bin/diskinserted"
cp rip_dvd "/usr/bin/rip_dvd"
cp abcde.conf "/etc/abcde.conf"

chmod a+x "/usr/bin/diskinserted"
chmod a+x "/usr/bin/rip_dvd"

if [ ! -e "/root/diskinserted.conf" -a -e "diskinserted.conf.example" ]; then
	cp "diskinserted.conf.example" "/root/diskinserted.conf"
fi;

echo "Restarting HAL to enable diskinserted scripts."
invoke-rc.d hal force-reload

echo "Done."