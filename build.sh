#!/bin/bash
# Module #
readonly EXIT_SUCCESS=0
readonly EXIT_FAILURE=1
readonly EOF=255
readonly moduleName="Bypasser"
readonly moduleId="bypasser"
readonly moduleVersion="$(date +%Y%m%d%H)"
readonly moduleFolderPath="$(dirname "$0")"

function setPermissions
{
	returnCode=${EXIT_SUCCESS}
	find . -type d -exec chmod 755 {} \;
	if [[ $? != ${EXIT_SUCCESS} ]];
	then
		returnCode=${EXIT_FAILURE}
	fi
	find . ! -name "LICENSE" ! -name "build.sh" ! -name "*.sha512" -type f -exec chmod 644 {} \;
	if [[ $? != ${EXIT_SUCCESS} ]];
	then
		returnCode=${EXIT_FAILURE}
	fi
	find . -name "*.sha512" -type f -exec chmod 444 {} \;
	if [[ $? != ${EXIT_SUCCESS} ]];
	then
		returnCode=${EXIT_FAILURE}
	fi
	chmod 444 "LICENSE"
	if [[ $? != ${EXIT_SUCCESS} ]];
	then
		returnCode=${EXIT_FAILURE}
	fi
	chmod 744 "build.sh"
	if [[ $? != ${EXIT_SUCCESS} ]];
	then
		returnCode=${EXIT_FAILURE}
	fi
	return ${returnCode}
}

echo "Welcome to the builder for the ``${moduleName}`` Magisk Module! "
echo "The absolute path to this script is \"$(cd "$(dirname "$0")" && pwd)/$(basename "$0")\". "
chmod 755 "${moduleFolderPath}" && cd "${moduleFolderPath}"
if [[ $? == ${EXIT_SUCCESS} && "$(basename "$(pwd)")" == "${moduleName}" ]]; then
	echo "The current working directory is \"$(pwd)\". "
else
	echo "The working directory \"$(pwd)\" is unexpected. "
	exit ${EOF}
fi
setPermissions
if [[ $? == ${EXIT_SUCCESS} ]];
then
	echo "Successfully set permissions. "
else
	echo "Failed to set permissions. "
fi

# Check #
readonly srcFolderPath="src"

find . -name "*.sh" -exec bash -n {} \;
if [[ $? == ${EXIT_SUCCESS} ]];
then
	echo "All the scripts successfully passed the local shell syntax check (bash). "
else
	echo "Some of the scripts failed to pass the local shell syntax check (bash). "
	exit ${EXIT_FAILURE}
fi

# Pack #
readonly propFileName="module.prop"
readonly propFilePath="${srcFolderPath}/${propFileName}"
readonly propContent="id=${moduleId}\n\
name=${moduleName}\n\
version=v${moduleVersion}\n\
versionCode=${moduleVersion}\n\
author=TMLP Team\n\
description=This is a developing Magisk module for bypassing Android environment detection related to TMLP. The abbreviation \"TMLP\" stands for anything related to TWRP, Magisk, LSPosed, and Plugins. \n\
updateJson=https://raw.githubusercontent.com/TMLP-Team/Bypasser/main/Update.json"
readonly zipFolderPath="Release"
readonly zipFileName="${moduleName}_v${moduleVersion}.zip"
readonly zipFilePath="${zipFolderPath}/${zipFileName}"

if [[ -d "${srcFolderPath}" && -d "${srcFolderPath}/META-INF" && -d "${srcFolderPath}/system" ]]; then
	echo "Sources were found to be packed. "
	echo -e "${propContent}" > "${propFilePath}"
	if [[ $? -eq ${EXIT_SUCCESS} && -e "${propFilePath}" ]]; then
		echo "Successfully generated the property file \"${propFilePath}\". "
		find "${srcFolderPath}" -type f -name "*.sha512" -delete
		if [[ $? -eq ${EXIT_SUCCESS} ]];
		then
			echo "Successfully removed all the previous SHA-512 value files. "
		else
			echo "Failed to remove all the previous SHA-512 value files. "
		fi
		find "${srcFolderPath}" -type f | while read file;
		do
			echo -n "$(sha512sum "${file}" | cut -d " " -f1)" > "${file}.sha512"
			if [[ $? -eq ${EXIT_SUCCESS} && -e "${file}.sha512" ]];
			then
				echo "Successfully generated the SHA-512 value file of \"${file}\". "
			else
				echo "Failed to generate the SHA-512 value file of \"${file}\". "
			fi
		done
		if [[ ! -d "${zipFolderPath}" ]]; then
			mkdir -p "${zipFolderPath}"
		fi
		if [[ -d "${zipFolderPath}" ]]; then
			echo "Successfully created the ZIP folder path \"${zipFolderPath}\". "
			(cd "${srcFolderPath}" && zip -J -ll -r -v - *) > "${zipFilePath}"
			if [[ $? -eq ${EXIT_SUCCESS} && -f "${zipFilePath}" ]]; then
				echo "Successfully packed the ${moduleName} Magisk module to \"${zipFilePath}\" via the ``zip`` command! "
			else
				echo "Failed to pack the ${moduleName} Magisk module to \"${zipFilePath}\" via the ``zip`` command. "
				exit 2
			fi
		else
			echo "Failed to create the ZIP folder path \"${zipFolderPath}\". "
			exit 3
		fi
	else
		echo "Failed to generate the property file \"${propFilePath}\". "
		exit 4
	fi
else
	echo "No sources were found to be packed. "
	exit 5
fi

# Log #
readonly changelogFolderPath="Changelog"
readonly changelogFileName="${moduleName}_v${moduleVersion}.md"
readonly changelogFilePath="${changelogFolderPath}/${changelogFileName}"

if [[ ! -d "${changelogFolderPath}" ]]; then
	mkdir -p "${changelogFolderPath}"
fi
if [[ -d "${changelogFolderPath}" ]]; then
	echo "Successfully created the log folder path \"${changelogFolderPath}\". "
	echo -e "## ${moduleName}_v${moduleVersion}\n" > "${changelogFilePath}"
	if [[ $? -eq ${EXIT_SUCCESS} && -f "${changelogFilePath}" ]]; then
		echo "Successfully created the log \"${changelogFilePath}\". "
		if [[ $# -ge 1 ]]; then
			for arg in "$@"
			do
				echo "${arg}" >> "${changelogFilePath}"
			done
		else
			echo "Please write down your changelog: "
			read changelog
			echo "${changelog}" >> "${changelogFilePath}"
		fi
		if [[ $? -eq ${EXIT_SUCCESS} && -f "${changelogFilePath}" ]]; then
			echo "Successfully wrote the change log to \"${changelogFilePath}\". "
		else
			echo "Failed to write the change log to \"${changelogFilePath}\". "
			exit 6
		fi
	else
		echo "Failed to create the log \"${changelogFilePath}\". "
		exit 7
	fi
else
	echo "Failed to create the log folder path \"${changelogFolderPath}\". "
	exit 8
fi

# Update #
readonly updateFolderPath="."
readonly updateFileName="Update.json"
readonly updateFilePath="${updateFolderPath}/${updateFileName}"
readonly updateContent="{\n\
	\"version\":\"v${moduleVersion}\", \n\
	\"versionCode\":${moduleVersion}, \n\
	\"zipUrl\":\"https://raw.githubusercontent.com/TMLP-Team/Bypasser/main/${zipFilePath}\", \n\
	\"changelog\":\"https://raw.githubusercontent.com/TMLP-Team/Bypasser/main/${changelogFilePath}\"\n\
}"

if [[ ! -d "${updateFolderPath}" ]]; then
	mkdir -p "${updateFolderPath}"
fi
if [[ -d "${updateFolderPath}" ]]; then
	echo "Successfully created the update folder path \"${updateFolderPath}\". "
	echo -e "$updateContent" > "${updateFilePath}"
	if [[ $? -eq ${EXIT_SUCCESS} && -f "${updateFilePath}" ]]; then
		echo "Successfully created the update JSON file \"${updateFilePath}\". "
	else
		echo "Failed to create the update JSON file \"${updateFilePath}\". "
		exit 9
	fi
else
	echo "Failed to create the update folder path \"${updateFolderPath}\". "
	exit 10
fi
setPermissions
if [[ $? == ${EXIT_SUCCESS} ]];
then
	echo "Successfully set permissions. "
else
	echo "Failed to set permissions. "
fi

# Git #
git add . && git commit -m "Module Update (${moduleVersion})" && git push
if [[ $? -eq ${EXIT_SUCCESS} ]]; then
	echo "Successfully pushed to GitHub. "
else
	echo "Failed to push to GitHub. "
	exit 11
fi

# Exit #
exit 0
