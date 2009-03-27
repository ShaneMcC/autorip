#!/bin/sh

if [ $(whoami) != "root" ]; then
	echo "This needs to be run as root."
	exit 1;
fi;

PHP=`which php`
if [ "${PHP}" = "" -a "${1}" != "--php" ]; then
	echo "PHP is required to run this script."
	echo "Please install PHP before running this script by using: "
	echo "sudo apt-get install php5-cli"
	echo ""
	echo "To do this automatically, please do:"
	echo "${0} --php"
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

if [ "${1}" = "--php" ]; then
	REQUIREDAPPS="${REQUIREDAPPS} php5-cli"
fi;

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

echo "Creating temp files.."
TEMPFILE=`mktemp`
TEMPFILE_DISKINSERTED=`mktemp`
TEMPFILE_RIPDVD=`mktemp`
TEMPFILE_ABCDE=`mktemp`

echo "Downloading latest update to scripts."
wget http://home.dataforce.org.uk/wiki/?AutoRipDVD -O ${TEMPFILE} -o /dev/null

extractFile() {
	FILENAME=${1}
	OUTPUT=${2}

	echo "Extracting ${FILENAME}"

	${PHP} -r '$foo = file_get_contents("'${TEMPFILE}'"); preg_match("@.*<h4>'${FILENAME}'</h4>.*?<pre>\n(.*?)\n</pre>.*@ums", $foo, $matches); echo html_entity_decode($matches[1]."\n");' > ${OUTPUT}
	mv ${OUTPUT} ${FILENAME}
	chmod a+xr ${FILENAME}
}

extractFile "/usr/bin/diskinserted" "${TEMPFILE_DISKINSERTED}"
extractFile "/usr/bin/rip_dvd" "${TEMPFILE_RIPDVD}"
extractFile "/etc/abcde.conf" "${TEMPFILE_ABCDE}"

echo "Restarting HAL to enable diskinserted scripts."
invoke-rc.d hal force-reload

echo "Done."