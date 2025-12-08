#!/bin/bash
podman build --volume ${PWD}/..:/build --tag onlyoffice-documentserver:v8.1.0 .
