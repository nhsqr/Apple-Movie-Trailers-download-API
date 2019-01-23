#!/bin/bash
MOVIE="$1"
json=`wget --no-check-certificate -qO - "http://www.apple.com/trailers/home/scripts/quickfind.php?callback=searchCallback&q=${MOVIE}" | grep -Pzo "^searchCallback\(\s*\K.*\}"`
error=`echo "$json" | jq '.error'`

if $error; then
	echo "Could not get callback from Apple"
	exit 1
else
	count=`echo "$json" | jq '.results | length'`
fi

if [ $count -gt 0 ]; then
	count=$(($count-1))
else
	echo "Movie not found"
	exit 0
fi

for i in `seq 0 $count`; do
	title=`echo "$json" | jq -r '.results['$i'].title'`
	if [[ "${title,,}" =~ "${MOVIE,,}" ]]; then
		location="$location"`echo "$json" | jq -r '.results['$i'].location'`"\n"
		found="$found"`echo "$json" | jq -r '.results['$i'].title'`"\n"
	fi
done

found=${found: 0:-2}
location=${location: 0:-2}
count=`echo -e "$found" | wc -l`
if [ $count -gt 1 ]; then
	echo "Found $count movies"
	echo "Choose which movie trailer you want to download:"
	echo -e "$found" | awk '{print NR,$0}'
	read -p "Number: " choice
else
	choice=1
fi

location=`echo -e "$location" | cut -d$'\n' -f "$choice"`
echo "Location: $location"

movieID=`wget --no-check-certificate -qO - "http://www.apple.com$location" | grep -Pzo "^.*\/movie\/detail\/\K[0-9]*"`
echo "ID: $movieID"

trailers=`curl -s "https://trailers.apple.com/trailers/feeds/data/$movieID.json" | jq -r '.clips[].versions.enus.sizes.hd720.srcAlt'`
count=`echo -e "$trailers" | wc -l`
if [ $count -gt 1 ]; then
	echo "Found $count trailers"
	echo "Choose which movie trailer you want to download:"
	echo -e "$trailers" | awk '{print NR,$0}'
	read -p "Number: " choice
else
	choice=1
fi

wget --no-check-certificate "`echo "$trailers" | cut -d$'\n' -f $choice`"
