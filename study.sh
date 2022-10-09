#!/usr/bin/env bash

gh auth status >/dev/null 2>/dev/null || gh auth login

node dispatcher.js "$1"
