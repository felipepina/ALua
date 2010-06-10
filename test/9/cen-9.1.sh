#!/bin/bash

lua d.lua 127.0.0.1 8888 &
sleep 1
lua d.lua 127.0.0.1 8889 &
sleep 1
lua d.lua 127.0.0.1 8890 &
sleep 1
lua p.lua 127.0.0.1 8888 cen-9.1.lua "127.0.0.1:8888/0" "127.0.0.1:8889/0" "127.0.0.1:8890/0" &