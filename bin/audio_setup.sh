#!/bin/sh

echo "Warning: There are some TODOs in this script."

device="all"

# Parse before because $1 can be unbound.
if [ "$1" == "-k" ]; then
	set -euo pipefail
	echo -n "Killing..."
	pkill jackd || echo "nothing to kill." && exit 1
	echo "Success."
elif [ "$1" == "-d" ]; then
	device="desktop"
elif [ "$1" == "-p" ]; then
	device="headphones"
elif [ "$1" == "-g" ]; then
	set -euo pipefail
	servername="$2"
	if [ "$servername" == "-d" ]; then
		export JACK_DEFAULT_SERVER=desktop
	elif [ "$servername" == "-p" ]; then
		export JACK_DEFAULT_SERVER=headphones
	fi
	echo "Starting yoshimi."
	pushd "$HOME/.config/yoshimi"
	yoshimi -J -j -c -S &
	popd
	echo "Starting qjackctl."
	qjackctl -n $JACK_DEFAULT_SERVER &
	echo "Done."
	sleep 1
	jack_connect -s headphones "alsa_pcm:Launchkey-MK2-49/midi_capture_1" "yoshimi:midi in"
	jack_connect -s headphones "alsa_pcm:Launchkey-MK2-49/midi_capture_2" "yoshimi:midi in"
	exit 0
fi

set -euo pipefail

echo "Killing pulseaudio."
pulseaudio --kill || true

# 5,1 is the stereo setup for arctis 7
#
# TODO: script for change in hardware
if [ "$device" == "headphones" ] || [ "$device" == "all" ]; then
	echo "Starting jackd for headphones,"
	/usr/bin/jackd -nheadphones -t9999 -dalsa -dhw:5,1 -r44100 -p512 -n2 -Xseq &
fi

if [ "$device" == "desktop" ] || [ "$device" == "all" ]; then
# TODO: script for change in hardware
	echo "Starting jackd for desktop,"
	/usr/bin/jackd -ndesktop -t9999 -dalsa -dhw:2 -r44100 -p512 -n2 -Xseq &
fi

echo "Starting pulseaudio."
pulseaudio --start

if [ "$device" == "headphones" ] || [ "$device" == "all" ]; then
	echo "Setting pulseaudio jack sinks for headphones."
	pactl load-module module-jack-sink channels=2 server_name=headphones
	pactl load-module module-jack-source channels=2 server_name=headphones
	echo "Setting default sink to jack_out for desktop."
	pacmd set-default-sink jack_out
fi

if [ "$device" == "desktop" ] || [ "$device" == "all" ]; then
	echo "Setting pulseaudio jack sinks for desktop."
	pactl load-module module-jack-sink channels=2 server_name=desktop
	pactl load-module module-jack-source channels=2 server_name=desktop
	echo "Setting default sink to jack_out for desktop."
	pacmd set-default-sink jack_out
fi
