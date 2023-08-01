#!/usr/bin/env bash

ESCAPE=$'\e'
STUB_REPLACEMENT="replace github.com/pebbe/zmq4 => ./scan/veracode-static-stub-zmq4"
PWD=`pwd`
APP_FOLDER_NAME=`basename $PWD`
USING_VENDOR_FOLDER=false

if [ -d vendor ]; then
  USING_VENDOR_FOLDER=true
fi

echo $USING_VENDOR_FOLDER

if [ ! -d scan ]; then
  mkdir scan
else
  rm -f -- scan/$APP_FOLDER_NAME.zip
fi

# Download and extract the Pipeline Scanner
if [ ! -f scan/pipeline-scan.jar ]; then
    echo "${ESCAPE}[0;36mDownloading Veracode Pipeline Scanner...${ESCAPE}[0m"
    curl -O https://downloads.veracode.com/securityscan/pipeline-scan-LATEST.zip
    unzip pipeline-scan-LATEST.zip pipeline-scan.jar
    mv pipeline-scan.jar scan/pipeline-scan.jar
    rm pipeline-scan-LATEST.zip
fi

echo "${ESCAPE}[0;36mPackaging for Veracode SAST...${ESCAPE}[0m"

if [ ! -d scan/veracode-static-stub-zmq4 ]; then
  echo "${ESCAPE}[0;36mDownloading stub...${ESCAPE}[0m"
  git clone git@github.com:antfie/veracode-static-stub-zmq4.git scan/veracode-static-stub-zmq4
fi

# The stub replacement should be appended to go.mod before running `go mod vendor`
if ! grep -q "$STUB_REPLACEMENT" go.mod; then
  echo >> go.mod
  echo "$STUB_REPLACEMENT" >> go.mod
fi

go mod vendor

cd ..
zip -r $APP_FOLDER_NAME/scan/$APP_FOLDER_NAME.zip $APP_FOLDER_NAME -x "$APP_FOLDER_NAME/scan/*" -x "$APP_FOLDER_NAME/.*" -x "$APP_FOLDER_NAME/*/.*" -x "*.md"
cd $APP_FOLDER_NAME

echo "${ESCAPE}[0;36mScanning with Veracode...${ESCAPE}[0m"
cd scan
java -jar pipeline-scan.jar --file $APP_FOLDER_NAME.zip
cd ..

echo "${ESCAPE}[0;36mCleaning up...${ESCAPE}[0m"

# Revert the go.mod file
sed -i "" -e "s|$STUB_REPLACEMENT||g" go.mod

# Remove the vendor folder if it was not previously there
if [ $USING_VENDOR_FOLDER = false ]; then
  rm -rf vendor
else
  # Otherwise restore the folder contents
  go mod vendor
fi

echo "${ESCAPE}[0;32mDone.${ESCAPE}[0m"