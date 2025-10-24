#!/usr/bin/env bash
nl_filter_errors() {
	awk -v inc="${NL_INCLUDE_TYPES[*]:-}" -v exc="${NL_EXCLUDE_TYPES[*]:-}" '
		BEGIN {
		ninc=split(inc, I, " "); nexc=split(exc, E, " ")
		for (i=1;i<=ninc;i++) if (I[i] != "") INC[toupper(I[i])]=1
		for (i=1;i<=nexc;i++) if (E[i] != "") EXC[toupper(E[i])]=1
		}
		/^ERR / {
		type=$2; keep=1; type_upper=toupper(type)
		if (ninc>0) {
			keep=0
			for (pattern in INC) {
				if (index(type_upper, pattern) > 0) { keep=1; break }
			}
		}
		for (pattern in EXC) {
			if (index(type_upper, pattern) > 0) { keep=0; break }
		}
		if (keep) print; next
		}
		/^FILE / { print }
	'
}

