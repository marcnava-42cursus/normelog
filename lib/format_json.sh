#!/usr/bin/env bash
nl_format_json() {
	local records="$1" stats="$2"
	awk -v RS='\n' -v ORS='\n' -v rec="$records" -v st="$stats" '
		BEGIN {
		print "{";
		ok=err=0; total=0
		n=split(st, S, "\n");
		for (i=1;i<=n;i++) {
			if (S[i] ~ /^STATS OK/) { split(S[i], a, " "); ok=a[3] }
			else if (S[i] ~ /^STATS ERR/) { split(S[i], a, " "); err=a[3] }
			else if (S[i] ~ /^TOTAL/) { split(S[i], a, " "); total=a[2] }
			else if (S[i] ~ /^TYPE /) {
			split(S[i], a, " "); types[a[2]]=a[3]
			}
		}
		printf "\"ok_files\": %d, \"error_files\": %d, \"total_errors\": %d, ", ok, err, total;
		printf "\"by_type\": {";
		first=1; for (t in types) { if (!first) printf ", "; printf "\"%s\": %d", t, types[t]; first=0 }
		printf "}, \"files\": [";
		m=split(rec, R, "\n"); curf=""; firstf=1; firste=1
		for (i=1;i<=m;i++) {
			if (R[i] ~ /^FILE /) {
			if (curf!="") printf "]}";
			if (!firstf) printf ", ";
			firstf=0; firste=1;
			split(R[i], a, " "); curf=a[2];
			printf "{\"file\": \"%s\", \"errors\": [", curf
			} else if (R[i] ~ /^ERR /) {
			if (!firste) printf ", ";
			firste=0;
			split(R[i], a, " ");
			printf "{\"type\":\"%s\",\"line\":%d,\"col\":%d,\"message\":\"", a[2], a[3], a[4];
			msg=index(R[i], a[5]);
			msg_text = substr(R[i], msg);
			gsub(/"/, "\\\"", msg_text);
			printf "%s\"}", msg_text
			}
		}
		if (curf!="") printf "]}";
		printf "]}\n"
		}'
}
