#!/bin/bash

lua d.lua 127.0.0.1 8888 &
sleep 1
lua p.lua 127.0.0.1 8888 cen-1.3.lua &
