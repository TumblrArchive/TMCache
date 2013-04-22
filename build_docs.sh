#!/usr/bin/env sh

appledoc \
    --company-id com.tumblr \
    --project-name TMCache \
    --project-company Tumblr \
    --project-version 1.0.0 \
    --docset-min-xcode-version 4.3 \
    --docset-bundle-id %COMPANYID.%PROJECTID \
    --docset-bundle-name %PROJECT \
    --docset-bundle-filename %COMPANYID.%PROJECTID-%VERSIONID.docset \
    --docset-feed-name %PROJECT \
    --docset-feed-url "http://tumblr.github.com/TMCache/docs/publish/%DOCSETATOMFILENAME" \
    --docset-package-url "http://tumblr.github.com/TMCache/docs/publish/%DOCSETPACKAGEFILENAME" \
    --docset-fallback-url http://tumblr.github.com/TMCache/ \
    --ignore "example" \
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
    --publish-docset \
    .
    
mv docs/docset docs/com.tumblr.TMCache-1.0.0.docset
rm docs/docset-installed.txt
