#!/usr/bin/env bash
nl_compute_stats() {
	awk '
		/^FILE / { if ($4=="OK") ok++; else err++; next }
		/^ERR / { type=$2; c[type]++; total++ }
		END {
			print "STATS OK", ok+0
			print "STATS ERR", err+0
			for (t in c) printf "TYPE %s %d\n", t, c[t]
			print "TOTAL", total+0
	}'
}
