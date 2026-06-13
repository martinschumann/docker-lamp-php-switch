#!/bin/bash

curl -sS -f -D - http://localsssssssssshost:80/ | egrep "Apache2 Ubuntu Default Page" > /dev/null || {
  echo "[ERROR] Expected content not found.";
  exit 1;
}