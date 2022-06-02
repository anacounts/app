#!/bin/sh
./prod/rel/anacounts_api/bin/anacounts_api eval "Anacounts.ReleaseTasks.migrate"
./prod/rel/anacounts_api/bin/anacounts_api start
