#!/usr/bin/env bash
nl_filter_errors() {
	awk -v inc="${NL_INCLUDE_TYPES[*]:-}" -v exc="${NL_EXCLUDE_TYPES[*]:-}" '
		BEGIN {
		ninc=split(inc, I, " "); nexc=split(exc, E, " ")
		for (i=1;i<=ninc;i++) if (I[i] != "") INC[I[i]]=1
		for (i=1;i<=nexc;i++) if (E[i] != "") EXC[E[i]]=1
		}
		/^ERR / {
		type=$2; keep=1
		if (ninc>0 && !(type in INC)) keep=0
		if (type in EXC) keep=0
		if (keep) print; next
		}
		/^FILE / { print }
	'
}

