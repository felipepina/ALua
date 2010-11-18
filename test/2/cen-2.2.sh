#!/bin/bash

lua d.lua 127.0.0.1 8888 &
sleep 1
lua d.lua 127.0.0.1 8889 "127.0.0.1:8888/0" &
sleep 1
lua d.lua 127.0.0.1 8890 "127.0.0.1:8889/0" &
sleep 1
lua p.lua 127.0.0.1 8888 cen-2.2.lua &