#!/bin/sh
./prod/rel/app_web/bin/app_web eval "App.ReleaseTasks.migrate"
./prod/rel/app_web/bin/app_web start
