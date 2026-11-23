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
rsync -R components/engage/PromptDialog.brs components/engage/CtaButton.xml components/engage/CtaButton.brs components/engage/PromptDialog.xml components/engage/consts.brs components/engage/PromptApi.brs components/engage/PromptApi.xml components/engage/LocalStorage.brs components/engage/PromptVideoDialog.brs components/engage/PromptVideoDialog.xml components/engage/PromptInline.* tmp/

# Copy IAP or NO IAP files
# components/engage/PromptManager.xml components/engage/PromptManager.brs
if [ "$IAP" = true ]
then
  rsync -R components/engage/PromptManager.xml components/engage/PromptManager.brs components/engage/PromotionManager.xml tmp/
else
  cp components/engage/PromptManager.xml.NOIAP tmp/components/engage/PromptManager.xml
  cp components/engage/PromptManager.brs.NOIAP tmp/components/engage/PromptManager.brs
  cp components/engage/PromotionManager.xml.NOIAP tmp/components/engage/PromotionManager.xml
fi

cd tmp
zip -r roku-sdk.zip *
mv roku-sdk.zip ../
