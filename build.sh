#!/bin/bash
mkdir out
podman build --build-arg PLATFORM=linux_arm64 --build-arg BRANCH=v8.1.0.178 --build-arg HTTP_PROXY=${HTTP_PROXY} --build-arg HTTPS_PROXY=${HTTPS_PROXY} --tag onlyoffice-document-editors-builder:v8.1.0 .
podman run --name onlyoffice-builder -v $PWD/out:/build_tools/out onlyoffice-document-editors-builder:v8.1.0
