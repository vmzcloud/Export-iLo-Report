function Load_HPEiLoCmdlets_Module {

	Import-Module HPEiLoCmdlets
}

function Export-Single-HTML-Page {
	param([string] $csvfilepath, [string] $htmlfilepath, [string] $heading)
	$HTML_Report_sytle = "<link rel=stylesheet type=text/css href=./mystyle.css charset=utf-8>"
	$HTML_Report_header = "<!DOCTYPE html><html><head><Title>$heading</Title>$HTML_Report_sytle</head><body><hr>"
	#$HTML_Report_menu = Export-Menu-HTML
	$today_modified = Get-date
	$Update_date = "Updated :" + $today_modified
	$html_input = "<hr><input type=text id=myInput onkeyup=myFunction() placeholder=`"Search for names..`" title=`"Type in a name`">"
	$html_content = Export-Table-HTML($csvfilepath)($heading)
	$HTML_Report_footer = "<script src=myscripts.js charset=UTF-8></script></body></html>"
	
	$HTML_Report = $HTML_Report_header + $HTML_Report_menu + $Update_date + $html_input + $html_content + $HTML_Report_footer
	
	$HTML_Report | Out-File $htmlfilepath
	Write-Host "File saved to $htmlfilepath"
}

function Export-Table-HTML {
	param([string] $filepath, [string] $heading)
	
	$txt = Import-CSV -Path $filepath
	[string]$txt2html = $txt | ConvertTo-Html 
	
	$txt2html -match "<body>(?<content>.*)</body>" | out-null
	$txt2html_tbl = $matches['content']
	
	$txt2html_tbl = $txt2html_tbl -replace "<table>","<table id=myTable>"
	
	$txt2html_tbl = Highlight-Keyword-in-HTML($txt2html_tbl)
	
	$heading = "<h2>$heading</h2>"
	$No_info = ""
	If (!$txt) {
		$No_info = "No Information"
	}
	$heading_table_html = $heading + $No_info + $txt2html_tbl
	
	Return $heading_table_html
}

function Highlight-Keyword-in-HTML {
	param([string] $html_content)
	
	#Bold 
	$html_content = $html_content -replace "Degraded","<b>Degraded</b>"
	
	#Red
	$html_content = $html_content -replace "<b>Degraded</b>","<p style=color:red;><b>Degraded</b></p>"
	
	Return $html_content
}

function Export-iLo-HTML {
	Export-Single-HTML-Page($CSV_iLo_file)($HTML_iLo_file)("iLo")
}

function Remove_iLO_CSV {
	$CSV_folder = ".\CSV"
	$CSV_iLo_file = "$CSV_folder\iLO_Status.csv"
	
	if (Test-Path -Path $CSV_iLo_file){
		Get-ChildItem $CSV_iLo_file | Remove-Item
		Write-Host "Removed $CSV_iLo_file"
	}
}

Load_HPEiLoCmdlets_Module

$CSV_folder = ".\CSV"
$CSV_iLo_file = "$CSV_folder\iLO_Status.csv"

$HTML_folder = ".\Report"
$HTML_iLo_file = "$HTML_folder\iLo.html"

Remove_iLO_CSV

$iLo_List = Import-CSV .\iLo.csv



Foreach($iLo in $iLo_List){
	$Connection = Connect-HPEiLO -IP $iLo.ip -Username $iLo.Username -Password $iLo.Password -DisableCertificateAuthentication -WarningAction SilentlyContinue
	$getServerInfo = Get-HPEiLOServerInfo -Connection $Connection
	
	$getServerInfo | select IP, ServerName, @{N='Serial';E={(Find-HPEiLO $iLo.ip).SerialNumber}}, @{N='ILOGen';E={$Connection.iLOGeneration}}, @{N='Server Family';E={$Connection.ServerFamily}},
		@{N='Server Model';E={$Connection.ServerModel}},@{N='Server Generation';E={$Connection.ServerGeneration}},
		@{N='Battery Status';E={$_.HealthSummaryInfo.BatteryStatus}}, @{N='BIOSHW Status';E={$_.HealthSummaryInfo.BIOSHardwareStatus}}, 
		@{N='FanRedundancy';E={$_.HealthSummaryInfo.FanRedundancy}},
		@{N='Fan Status';E={$_.HealthSummaryInfo.FanStatus}},
		@{N='Memory Status';E={$_.HealthSummaryInfo.MemoryStatus}},
		@{N='Network Status';E={$_.HealthSummaryInfo.NetworkStatus}},
		@{N='PowerSuppliesRedundancy';E={$_.HealthSummaryInfo.PowerSuppliesRedundancy}},
		@{N='PowerSupplies Status';E={$_.HealthSummaryInfo.PowerSuppliesStatus}},
		@{N='Processor Status';E={$_.HealthSummaryInfo.ProcessorStatus}},
		@{N='Storage Status';E={$_.HealthSummaryInfo.StorageStatus}},
		@{N='Temperature Status';E={$_.HealthSummaryInfo.TemperatureStatus}} | Export-CSV -Path $CSV_iLo_file -NoTypeInformation -Append
		
	Disconnect-HPEiLO -Connection $Connection
}
Write-Host "File saved to $CSV_iLo_file"
Export-iLo-HTML
