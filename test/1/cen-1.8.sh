#!/bin/bash

lua d.lua 127.0.0.1 8888 &
sleep 1
# lua p.lua 127.0.0.1 8888 cen-1.8.lua > cen-1.8.log &
lua p.lua 127.0.0.1 8888 cen-1.8.lua &
