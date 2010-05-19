#!/bin/bash

echo "Welcome to aEncoder Linux Beta"

echo "Testing binaries:"
echo "Your must have installed: tk8.5, mencoder, gpac >= 0.4.4"

for bins in wish8.5 tclsh mencoder MP4Box;
    do
	echo $bins":"
	tmppath=`which $bins`
	if [ ! $tmppath == "" ]; then
	echo "File $tmppath exist"
	else
	echo "Error: No $bins in PATH"
	exit 1
	fi
    done

if [ ! -f ~/.mplayer/subfont.ttf ]; then 
    echo "No subfont.ttf in ~/.mplayer directory!"
    exit 2
    else
    echo "subfont.ttf exist"
fi

echo "#!/bin/bash" > aEncoder
echo "" >> aEncoder
echo "`which wish8.5` aEncoder.tcl" >> aEncoder
chmod +x aEncoder

exit 0
