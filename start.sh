#!/bin/sh

# runs python3 http server on localhost:2784

# http://localhost:2784/

python3 -u -m http.server --cgi 2784 2>python3.log
