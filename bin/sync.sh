#!/bin/bash

log=/home/ec2-user/hugo/github/sync.log
echo "" > ${log}
echo  "/home/ec2-user/hugo/github/hugo-theme/sync.sh > /home/ec2-user/hugo/github/sync.log 2>&1 &"

echo "[INFO] Generating Markdown files from Wordpress "
cd /home/ec2-user/data/shwchurch/web/wp-content/plugins/wordpress-to-hugo-exporter-master
rm -rf /home/ec2-user/hugo/tmp/*
php hugo-export-cli.php ~/hugo/tmp/ 

cd /home/ec2-user/hugo/tmp/wp-hugo-tmp

#while [[ 1 ]]; do du -sh .; sleep 5; done;


echo "[INFO] Remove file more than ${fileSizeOfFilesToRemove}"
fileSizeOfFilesToRemove=+1M
cd /home/ec2-user/hugo/tmp/wp-hugo-tmp/wp-content/uploads/
find . -type f -size ${fileSizeOfFilesToRemove} -printf '%s %p\n' | sort -nr | awk '{print $2}' | grep -v 2019  | xargs -I {} rm "{}"


echo "[INFO] Copy all contents into Hugo folder"

rm -rf /home/ec2-user/hugo/github/t5/content/*
cp -r /home/ec2-user/hugo/tmp/wp-hugo-tmp/* /home/ec2-user/hugo/github/t5/content/



## file: ./strip-special-char.sh >/dev/null 2>&1 &


echo "[INFO] Stripping all links including special chars"

cd /home/ec2-user/hugo/github/t5/content/posts

echo "" > special-chars.txt 
echo "" > special-chars-shorted.txt 

grep -iRl "^url: /20" ./ | xargs cat | grep "^url: " | sed 's/url: //' >> special-chars.txt 2>/dev/null

declare -a SpecialChars=(
	"，" 
	"-" 
	"—" 
	"——" 
	"－－" 
	" " 
	"”" 
	"“" 
	"”" 
	"？" 
	"：" 
	"！" 
	"_" 
	"（" 
	"）" 
	"《" 
	"》" 
	"•" 
	"、" 
	"：" 
	"、" 
	"："
)

while IFS='' read -r line || [[ -n "$line" ]]; do

	escapedLine=${line}

	for SpecialChar in "${SpecialChars[@]}"; do
		escapedLine=$(printf '%s\n' "${escapedLine//${SpecialChar}/}")
	done

	if [[ ! -z "${escapedLine}" && "${escapedLine}" != "${line}" ]]; then

		pattern="s#${line}#${escapedLine}#g"
		echo "${pattern}" >> ./special-chars-shorted.txt
		echo "[INFO] ${pattern}"

		find . -type f -name "*.md" -exec sed -i "${pattern}" {} \; >/dev/null 2>&1
	fi
	
    
done < "./special-chars.txt"


cd /home/ec2-user/hugo/github/t5/
# cd /home/ec2-user/hugo/github/hugo-theme/
hugo server -D --baseUrl=http://54.151.194.5:1313/ --bind=0.0.0.0




# cp ../../../tmp/wp-hugo-tmp/posts/2019-04-06-耶和华对我说什么，我就说什么-2018年4月7日主日.md  ./post/

# [permalinks]
#   posts = "/:year/:month/:day/:title/" 
# url: /2019/04/06/耶和华对我说什么，我就说什么-2018年4月7日主日/


