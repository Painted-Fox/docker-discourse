#!/bin/bash
/etc/init.d/postfix start
/etc/init.d/nginx start
circusd circus.ini
