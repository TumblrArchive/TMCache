#!/usr/bin/env sh

appledoc \
    --company-id com.tumblr \
    --project-name TMCache \
    --project-company Tumblr \
    --project-version 1.0.4 \
    --docset-min-xcode-version 4.3 \
    --docset-bundle-id %COMPANYID.%PROJECTID \
    --docset-bundle-name "%PROJECT %VERSION" \
    --docset-bundle-filename %COMPANYID.%PROJECTID-%VERSIONID.docset \
    --ignore "tests" \
    --ignore "docs" \
    --ignore "*.m" \
    --no-repeat-first-par \
    --explicit-crossref \
    --clean-output \
    \
    --keep-undocumented-member \
    --no-keep-undocumented-object \
    --no-warn-undocumented-object \
    --no-warn-undocumented-member \
    \
    --keep-intermediate-files \
    --output ./docs \
    .
    
mv docs/docset docs/com.tumblr.TMCache-1.0.4.docset
rm docs/docset-installed.txt
