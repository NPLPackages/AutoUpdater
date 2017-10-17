# Author: leio
# Date: 2017.10.17
# Desc: Make an AutoUpdater.zip and embed it into AppLauncher
cmake_minimum_required(VERSION 3.2)

project (AutoUpdater)
##############################
file (GLOB_RECURSE AutoUpdater_NPL_FILES ${PROJECT_SOURCE_DIR}/npl_mod/AutoUpdater/*.lua)
SOURCE_GROUP("src\\" FILES ${AutoUpdater_NPL_FILES})
list(APPEND AutoUpdater_SRCS ${AutoUpdater_NPL_FILES})

##############################
file (GLOB_RECURSE AutoUpdater_CONFIG_FILES ${PROJECT_SOURCE_DIR}/npl_mod/AutoUpdater/configs/*.xml)
SOURCE_GROUP("src\\configs" FILES ${AutoUpdater_CONFIG_FILES})
list(APPEND AutoUpdater_SRCS ${AutoUpdater_CONFIG_FILES})

add_custom_target(AutoUpdater
	COMMAND ${CMAKE_COMMAND} -E tar "cfv" "${PROJECT_BINARY_DIR}/AutoUpdater.zip" --format=zip ${PROJECT_SOURCE_DIR}/npl_mod/AutoUpdater
	WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
	COMMENT "making AutoUpdater zip archive"
	SOURCES ${AutoUpdater_SRCS})