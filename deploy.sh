#!/bin/bash

function fetch_semester {
	local semester=$1
	echo Fetching semester $semester...

	local courses_file=courses_$semester

	cd technion-ug-info-fetcher
	php courses_to_json.php "courses_list_from_rishum=$semester&try_until_all_downloaded=true" || {
		cd ..
		echo courses_to_json failed
		return 1
	}
	cd ..

	local src_file=technion-ug-info-fetcher/$courses_file.json
	local dest_file_min=deploy/courses/$courses_file.min.js
	local dest_file=deploy/courses/$courses_file.js

	echo -n 'var courses_from_rishum = ' > $dest_file_min
	cat $src_file >> $dest_file_min

	echo -n 'var courses_from_rishum = ' > $dest_file
	local php_cmd="echo json_encode(json_decode(file_get_contents('$src_file')), JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);"
	php -r "$php_cmd" >> $dest_file

	return 0
}

# temporary for testing, TODO: remove
function send_cache_and_exit {
	echo Zipping and uploading cache...

	local filename=`date '+%Y-%m-%d-%H-%M-%S'`.zip
	zip -q -r "$filename" technion-ug-info-fetcher/course_info_cache

	curl -s -F name=$filename -F file=@$filename https://uguu.se/api.php?d=upload-tool

	echo
	echo Done
	exit $1
}

fetch_semester 201702 || send_cache_and_exit 1
fetch_semester 201703 || send_cache_and_exit 1
fetch_semester 201801 || send_cache_and_exit 1

send_cache_and_exit 0
