#!/bin/bash
if [ -z "$1" ]
then
  echo "Usage: build-sdk.sh [iap/noiap]"
  exit 1
fi

if [ "$1" = "iap" ]
then
  echo "Building SDK with IAP"
  IAP=true
else
  echo "Building SDK without IAP"
  IAP=false
fi

# Prep tmp directory
rm -rf tmp
mkdir -p tmp

# Copy common files
rsync -R components/redfast/PromotionDialog.brs components/redfast/CtaButton.xml components/redfast/CtaButton.brs components/redfast/PromotionDialog.xml components/redfast/consts.brs components/redfast/PromotionApi.brs components/redfast/PromotionApi.xml components/redfast/LocalStorage.brs components/redfast/PromotionVideoDialog.brs components/redfast/PromotionVideoDialog.xml components/redfast/PromotionInline.* components/redfast/PromotionSurvey.* tmp/

# Copy IAP or NO IAP files
# components/redfast/PromotionManager.xml components/redfast/PromotionManager.brs
if [ "$IAP" = true ]
then
  rsync -R components/redfast/PromotionManager.xml components/redfast/PromotionManager.brs tmp/
else
  cp components/redfast/PromotionManager.xml.NOIAP tmp/components/redfast/PromotionManager.xml
  cp components/redfast/PromotionManager.brs.NOIAP tmp/components/redfast/PromotionManager.brs
fi

cd tmp
zip -r roku-sdk.zip *
mv roku-sdk.zip ../
