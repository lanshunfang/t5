#!/bin/bash

protectedMp3FromDeletedRequiredInMarkdownFileNamePattern=2019

tmpPathPrefix=/home/ec2-user/hugo/tmp/
hugoExportedPath=${tmpPathPrefix}/wp-hugo-delta-processing

log=/home/ec2-user/hugo/github/sync.log

githubHugoPath=/home/ec2-user/hugo/github/t5/
wodrePressHugoExportPath=/home/ec2-user/data/shwchurch/web/wp-content/plugins/wordpress-to-hugo-exporter


echo "" > ${log}
echo  "/home/ec2-user/hugo/github/hugo-theme/sync.sh > /home/ec2-user/hugo/github/sync.log 2>&1 &"


echo "[INFO] Cleanup ${hugoExportedPath}"
if [[ ! -z "$hugoExportedPath" && -d "${hugoExportedPath}" ]]; then
	rm -rf ${hugoExportedPath}
fi

echo "[INFO] Generating Markdown files from Wordpress "
cd ${wodrePressHugoExportPath}
#git stash
#git pull

# php hugo-export-cli.php ${tmpPathPrefix} > /home/ec2-user/hugo/github/sync.log 2>&1 &
php hugo-export-cli.php ${tmpPathPrefix} 

#cd /home/ec2-user/hugo/tmp/wp-hugo-tmp
cd ${hugoExportedPath}

#while [[ 1 ]]; do du -sh .; sleep 5; done;

echo "[INFO] Remove file more than ${fileSizeOfFilesToRemove} that is not required from ${protectedMp3FromDeletedRequiredInMarkdownFileNamePattern}"
postDir=${hugoExportedPath}/posts
uploadsDir=${hugoExportedPath}/wp-content/uploads/
cd ${postDir}
allMp3RequiredDescriptor=uploaded-files-required.txt 
allMp3Descriptor=uploaded-files.txt
allMp3ToDeleteDescriptor=uploaded-files-to-delete.txt 

grep -iRl "\.mp3" ./ | grep ${protectedMp3FromDeletedRequiredInMarkdownFileNamePattern} | xargs cat | grep "/.*\.mp3>" | perl -pe "s|.*/(.*?\.mp3).*|\1|g"  > ${allMp3RequiredDescriptor}
echo "" > ${uploadsDir}/${allMp3ToDeleteDescriptor}

fileSizeOfFilesToRemove=+1M

cd ${uploadsDir}
#find . -type f -size ${fileSizeOfFilesToRemove} -printf '%s %p\n' | sort -nr | awk '{print $2}' | grep -v 2019  | xargs -I {} rm "{}"
# find wp-content/uploads/ -type f -size ${fileSizeOfFilesToRemove} -printf '%s %p\n' | sort -nr | awk '{print $2}'  > ${allMp3Descriptor}
find . -type f -size ${fileSizeOfFilesToRemove} -printf '%s %p\n' | sort -nr | awk '{print $2}'  > ${allMp3Descriptor}

echo "[INFO] Generating all files to delete"
while IFS='' read -r line || [[ -n "$line" ]]; do

	isMp3Required=$(cat ${postDir}/${allMp3RequiredDescriptor} | xargs -I {}  bash -c "[[ \"${line}\" =~ \"{}\" ]] && echo {}" )

	if [[ -z "$isMp3Required" ]];then
		echo $line >> ${uploadsDir}/${allMp3ToDeleteDescriptor} 
	else
		echo "[INFO] Skip marking deletion: '$line' as it is required"
	fi

	  
done < "${uploadsDir}/${allMp3Descriptor}"

echo "[INFO] Delete files in ${uploadsDir}/${allMp3ToDeleteDescriptor}"

cd ${uploadsDir}

while IFS='' read -r line || [[ -n "$line" ]]; do

	if [[ ! -z "$line" ]];then
		rm $line
	fi

	  
done < "${uploadsDir}/${allMp3ToDeleteDescriptor}"


echo "[INFO] Delete other unnecessary files"

rm -rf ./ftp/choir-mp3/

echo "[INFO] Copy all contents into Hugo folder for publishing"

rm -rf ${githubHugoPath}/content/*
if [[ ! -z "${hugoExportedPath}" && -d "${hugoExportedPath}"  ]];then
	#cp -nr ${hugoExportedPath}/* ${githubHugoPath}/content/
	cp -r ${hugoExportedPath}/* ${githubHugoPath}/content/
fi


## file: ./strip-special-char.sh >/dev/null 2>&1 &


#echo "[INFO] Stripping all links including special chars"

#cd /home/ec2-user/hugo/github/t5/content/posts

##echo "" > special-chars.txt 
##echo "" > special-chars-shorted.txt 
##
##grep -iRl "^url: /20" ./ | xargs cat | grep "^url: " | sed 's/url: //' >> special-chars.txt 2>/dev/null

##declare -a SpecialChars=(
##	"　" 
##	"，" 
##	"-" 
##	"—" 
##	"——" 
##	"－－" 
##	" " 
##	"”" 
##	"“" 
##	"”" 
##	"？" 
##	"：" 
##	"！" 
##	"_" 
##	"（" 
##	"）" 
##	"《" 
##	"》" 
##	"•" 
##	"、" 
##	"：" 
##	"、" 
##	"："
##	"＠"
##)
##
##while IFS='' read -r line || [[ -n "$line" ]]; do
##
##	escapedLine=${line}
##
##	for SpecialChar in "${SpecialChars[@]}"; do
##		escapedLine=$(printf '%s\n' "${escapedLine//${SpecialChar}/}")
##	done
##
##	if [[ ! -z "${escapedLine}" && "${escapedLine}" != "${line}" ]]; then
##
##		pattern="s#${line}#${escapedLine}#g"
##		echo "${pattern}" >> ./special-chars-shorted.txt
##		echo "[INFO] ${pattern}"
##
##		find . -type f -name "*.md" -exec sed -i "${pattern}" {} \; >/dev/null 2>&1
##	fi
##	
##    
##done < "./special-chars.txt"
##

echo "[INFO] Replace all special chars in Markdown Title"

cd ${githubHugoPath}/content/posts

declare -a SpecialCharsInTitle=(
        '@::＠'
)

for SpecialChar in "${SpecialCharsInTitle[@]}"; do
        KEY="${SpecialChar%%::*}"
        VALUE="${SpecialChar##*::}"
        pattern="s#${KEY}#${VALUE}#g"
        find . -type f -name "*.md" -exec sed -i "${pattern}" {} \;
done


cd ${githubHugoPath}/bin/

echo "[INFO] Deploy and publish to github pages"
./deploy.sh
# cd /home/ec2-user/hugo/github/hugo-theme/
#hugo server -D --baseUrl=http://54.151.194.5:1313/ --bind=0.0.0.0




# cp ../../../tmp/wp-hugo-tmp/posts/2019-04-06-耶和华对我说什么，我就说什么-2018年4月7日主日.md  ./post/

# [permalinks]
#   posts = "/:year/:month/:day/:title/" 
# url: /2019/04/06/耶和华对我说什么，我就说什么-2018年4月7日主日/


