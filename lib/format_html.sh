#!/usr/bin/env bash
# HTML output formatter for normelog

nl_format_html() {
	local filtered="$1"
	local stats="$2"
	local severity_stats="${3:-}"

	# Extract statistics
	local ok_files=0
	local err_files=0
	local total_errors=0
	local critical_count=0
	local warning_count=0
	local info_count=0

	while IFS= read -r line; do
		if [[ $line =~ ^OK_FILES\ (.+)$ ]]; then
			ok_files="${BASH_REMATCH[1]}"
		elif [[ $line =~ ^ERR_FILES\ (.+)$ ]]; then
			err_files="${BASH_REMATCH[1]}"
		elif [[ $line =~ ^TOTAL_ERRORS\ (.+)$ ]]; then
			total_errors="${BASH_REMATCH[1]}"
		fi
	done <<<"$stats"

	# Parse severity stats if available
	if [[ -n "$severity_stats" ]]; then
		while IFS= read -r line; do
			if [[ $line =~ ^SEVERITY_CRITICAL\ (.+)$ ]]; then
				critical_count="${BASH_REMATCH[1]}"
			elif [[ $line =~ ^SEVERITY_WARNING\ (.+)$ ]]; then
				warning_count="${BASH_REMATCH[1]}"
			elif [[ $line =~ ^SEVERITY_INFO\ (.+)$ ]]; then
				info_count="${BASH_REMATCH[1]}"
			fi
		done <<<"$severity_stats"
	fi

	# Generate HTML
	{
	cat <<'HTML_HEADER'
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>normelog - Norminette Analysis Report</title>
	<style>
		* { margin: 0; padding: 0; box-sizing: border-box; }
		body {
			font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
			line-height: 1.6;
			color: #333;
			background: #f5f5f5;
			padding: 20px;
		}
		.container {
			max-width: 1200px;
			margin: 0 auto;
			background: white;
			border-radius: 8px;
			box-shadow: 0 2px 10px rgba(0,0,0,0.1);
			overflow: hidden;
		}
		header {
			background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
			color: white;
			padding: 30px;
			text-align: center;
		}
		header h1 {
			font-size: 2.5em;
			margin-bottom: 10px;
		}
		header p {
			opacity: 0.9;
			font-size: 1.1em;
		}
		.summary {
			display: grid;
			grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
			gap: 20px;
			padding: 30px;
			background: #fafafa;
		}
		.stat-card {
			background: white;
			padding: 20px;
			border-radius: 6px;
			box-shadow: 0 1px 3px rgba(0,0,0,0.1);
			text-align: center;
		}
		.stat-card h3 {
			font-size: 0.9em;
			text-transform: uppercase;
			color: #666;
			margin-bottom: 10px;
			letter-spacing: 0.5px;
		}
		.stat-card .number {
			font-size: 2.5em;
			font-weight: bold;
			margin-bottom: 5px;
		}
		.stat-card.ok .number { color: #10b981; }
		.stat-card.error .number { color: #ef4444; }
		.stat-card.critical .number { color: #dc2626; }
		.stat-card.warning .number { color: #f59e0b; }
		.stat-card.info .number { color: #3b82f6; }
		.content {
			padding: 30px;
		}
		.section {
			margin-bottom: 40px;
		}
		.section h2 {
			font-size: 1.8em;
			margin-bottom: 20px;
			color: #667eea;
			border-bottom: 2px solid #667eea;
			padding-bottom: 10px;
		}
		.error-types {
			display: grid;
			gap: 10px;
		}
		.error-type-row {
			display: flex;
			justify-content: space-between;
			align-items: center;
			padding: 12px 15px;
			background: #f9fafb;
			border-left: 4px solid #667eea;
			border-radius: 4px;
		}
		.error-type-row:hover {
			background: #f3f4f6;
		}
		.error-type-name {
			font-family: 'Courier New', monospace;
			font-weight: 600;
			color: #374151;
		}
		.error-type-count {
			background: #667eea;
			color: white;
			padding: 4px 12px;
			border-radius: 12px;
			font-weight: bold;
			font-size: 0.9em;
		}
		.file-section {
			margin-bottom: 30px;
		}
		.file-header {
			background: #1f2937;
			color: white;
			padding: 12px 15px;
			font-family: 'Courier New', monospace;
			font-size: 1.1em;
			border-radius: 4px 4px 0 0;
			display: flex;
			justify-content: space-between;
			align-items: center;
		}
		.file-error-count {
			background: #ef4444;
			padding: 4px 10px;
			border-radius: 10px;
			font-size: 0.85em;
		}
		.error-list {
			border: 1px solid #e5e7eb;
			border-top: none;
			border-radius: 0 0 4px 4px;
		}
		.error-item {
			padding: 15px;
			border-bottom: 1px solid #e5e7eb;
			display: grid;
			grid-template-columns: auto 1fr;
			gap: 15px;
		}
		.error-item:last-child {
			border-bottom: none;
		}
		.error-item:hover {
			background: #f9fafb;
		}
		.error-meta {
			display: flex;
			flex-direction: column;
			gap: 5px;
			min-width: 150px;
		}
		.error-type-badge {
			background: #dc2626;
			color: white;
			padding: 4px 8px;
			border-radius: 4px;
			font-size: 0.75em;
			font-family: 'Courier New', monospace;
			font-weight: bold;
			text-align: center;
		}
		.error-location {
			color: #6b7280;
			font-size: 0.9em;
			font-family: 'Courier New', monospace;
		}
		.error-message {
			color: #374151;
			padding-top: 5px;
		}
		footer {
			background: #f9fafb;
			padding: 20px;
			text-align: center;
			color: #6b7280;
			font-size: 0.9em;
			border-top: 1px solid #e5e7eb;
		}
		.no-errors {
			text-align: center;
			padding: 60px 20px;
			color: #10b981;
		}
		.no-errors svg {
			width: 80px;
			height: 80px;
			margin-bottom: 20px;
		}
		.no-errors h3 {
			font-size: 2em;
			margin-bottom: 10px;
		}
		@media (max-width: 768px) {
			.summary {
				grid-template-columns: 1fr;
			}
			header h1 {
				font-size: 2em;
			}
		}
	</style>
</head>
<body>
	<div class="container">
		<header>
			<h1>📋 normelog Report</h1>
			<p>Norminette Analysis Results</p>
		</header>

		<div class="summary">
			<div class="stat-card ok">
				<h3>Correct Files</h3>
				<div class="number">OK_FILES_PLACEHOLDER</div>
			</div>
			<div class="stat-card error">
				<h3>Files with Errors</h3>
				<div class="number">ERR_FILES_PLACEHOLDER</div>
			</div>
			<div class="stat-card error">
				<h3>Total Errors</h3>
				<div class="number">TOTAL_ERRORS_PLACEHOLDER</div>
			</div>
HTML_HEADER

	# Add severity breakdown if available
	if [[ -n "$severity_stats" && $total_errors -gt 0 ]]; then
		cat <<HTML_SEVERITY
			<div class="stat-card critical">
				<h3>Critical</h3>
				<div class="number">CRITICAL_PLACEHOLDER</div>
			</div>
			<div class="stat-card warning">
				<h3>Warnings</h3>
				<div class="number">WARNING_PLACEHOLDER</div>
			</div>
			<div class="stat-card info">
				<h3>Info</h3>
				<div class="number">INFO_PLACEHOLDER</div>
			</div>
HTML_SEVERITY
	fi

	cat <<'HTML_CONTENT_START'
		</div>

		<div class="content">
HTML_CONTENT_START

	# If no errors, show success message
	if [[ $total_errors -eq 0 ]]; then
		cat <<'HTML_NO_ERRORS'
			<div class="no-errors">
				<svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
				</svg>
				<h3>All Clear!</h3>
				<p>No norminette errors found. Great job!</p>
			</div>
HTML_NO_ERRORS
	else
		# Show error type breakdown
		cat <<'HTML_ERROR_TYPES_START'
			<div class="section">
				<h2>Error Type Breakdown</h2>
				<div class="error-types">
HTML_ERROR_TYPES_START

		# Extract error type counts from stats
		echo "$stats" | awk '
			/^TYPE / {
				type_name = $2
				count = $3
				print "<div class=\"error-type-row\">"
				print "  <span class=\"error-type-name\">" type_name "</span>"
				print "  <span class=\"error-type-count\">" count "</span>"
				print "</div>"
			}
		'

		cat <<'HTML_ERROR_TYPES_END'
				</div>
			</div>

			<div class="section">
				<h2>Detailed Error Listing</h2>
HTML_ERROR_TYPES_END

		# Group errors by file
		awk '
			BEGIN {
				current_file = ""
				error_count = 0
			}
			/^FILE / {
				if (current_file != "" && error_count > 0) {
					print "</div>"
					print "</div>"
				}
				current_file = $2
				error_count = 0
			}
			/^ERR / {
				if (error_count == 0) {
					file_esc = current_file
					gsub(/&/, "\\&amp;", file_esc)
					gsub(/</, "\\&lt;", file_esc)
					gsub(/>/, "\\&gt;", file_esc)
					gsub(/"/, "\\&quot;", file_esc)
					print "<div class=\"file-section\">"
					print "  <div class=\"file-header\">"
					print "    <span>" file_esc "</span>"
					print "    <span class=\"file-error-count\"></span>"
					print "  </div>"
					print "  <div class=\"error-list\">"
				}
				error_count++

				type = $2
				line = $3
				col = $4
				message = substr($0, index($0, $5))

				# Escape HTML
				gsub(/&/, "\\&amp;", message)
				gsub(/</, "\\&lt;", message)
				gsub(/>/, "\\&gt;", message)
				gsub(/"/, "\\&quot;", message)

				print "    <div class=\"error-item\">"
				print "      <div class=\"error-meta\">"
				print "        <span class=\"error-type-badge\">" type "</span>"
				print "        <span class=\"error-location\">Line " line ", Col " col "</span>"
				print "      </div>"
				print "      <div class=\"error-message\">" message "</div>"
				print "    </div>"
			}
			END {
				if (current_file != "" && error_count > 0) {
					print "</div>"
					print "</div>"
				}
			}
		' <<<"$filtered"

		# Add JavaScript to count errors per file
		cat <<'HTML_SCRIPT'
			</div>

			<script>
				// Count and display errors per file
				document.querySelectorAll('.file-section').forEach(section => {
					const errors = section.querySelectorAll('.error-item');
					const badge = section.querySelector('.file-error-count');
					if (badge) {
						const count = errors.length;
						badge.textContent = count + ' error' + (count !== 1 ? 's' : '');
					}
				});
			</script>
HTML_SCRIPT
	fi

	cat <<'HTML_FOOTER'
		</div>

		<footer>
			<p>Generated by <strong>normelog</strong> - A wrapper around norminette for 42 School</p>
			<p style="margin-top: 5px; font-size: 0.85em;">
				Report generated on TIMESTAMP_PLACEHOLDER
			</p>
		</footer>
	</div>
</body>
</html>
HTML_FOOTER
} | sed -e "s/OK_FILES_PLACEHOLDER/$ok_files/g" \
		-e "s/ERR_FILES_PLACEHOLDER/$err_files/g" \
		-e "s/TOTAL_ERRORS_PLACEHOLDER/$total_errors/g" \
		-e "s/CRITICAL_PLACEHOLDER/$critical_count/g" \
		-e "s/WARNING_PLACEHOLDER/$warning_count/g" \
		-e "s/INFO_PLACEHOLDER/$info_count/g" \
		-e "s|TIMESTAMP_PLACEHOLDER|$(date '+%Y-%m-%d %H:%M:%S')|g"
}
