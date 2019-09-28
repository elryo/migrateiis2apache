Class migrateiis2apache.services.RepairCaseServices
{
 ClassMethod findCaseError(
 	gitSourceDirectory As %String,
 	webFileDirectory As %String, 
 	detailMode As %Boolean=1,
 	verbose As %Boolean = 0,
 	dumpReportDirectory As %String) As %DynamicObject
 {
 	#dim rf As migrateiis2apache.RefFindAndReplace
 	Set rf = ##class(migrateiis2apache.RefFindAndReplace).%New(webFileDirectory,gitSourceDirectory,verbose)
 	$$$TOE(tSc,rf.find())
 	
 	If (dumpReportDirectory'="") {
  		$$$TOE(tSc,..dumpFindReport(rf,dumpReportDirectory))
  	}
 	
 	Return $Select(detailMode:rf.getFindReportDetail(),1:rf.getFindReportSummary())
 }
 
 ClassMethod findAndRepairCaseError(
 	gitSourceDirectory As %String, 
 	webFileDirectory As %String, 
 	detailMode As %Boolean=1,
 	verbose As %Boolean = 0,
 	dumpReportDirectory As %String) As %DynamicObject
 {
  	#dim rf As migrateiis2apache.RefFindAndReplace
  	Set rf = ##class(migrateiis2apache.RefFindAndReplace).%New(webFileDirectory,gitSourceDirectory,verbose), tSc = $$$OK
  	$$$TOE(tSc,rf.find())
  	$$$TOE(tSc,rf.replace())
  	
  	If (dumpReportDirectory'="") {
  		$$$TOE(tSc,..dumpAllReport(rf,dumpReportDirectory))
  	}
  	
  	Return $Select(detailMode:rf.getReplaceReportDetail(),1:rf.getReplaceReportSummary())
 }
 
 ClassMethod dumpFindReport(rf As migrateiis2apache.RefFindAndReplace, directory As %String) As %Status [ Private ]
 {
 	Set tSc = $$$OK, normalizedDirectory = ##class(%File).NormalizeDirectory(directory)
  	Try{
  		Set ts = $tr($zdt($h,8),"-: ","")
  		$$$TOE(tSc,..dumpJSONtoFile(rf.getFindReportDetail(),normalizedDirectory_"FindReportDetail-"_ts_".json"))
  		$$$TOE(tSc,..dumpJSONtoFile(rf.getFindReportSummary(),normalizedDirectory_"FindReportSummary-"_ts_".json"))
  	}Catch(ex) {
  		Set tSc = e.AsStatus()
  	}
  	Return tSc
 }
 
 ClassMethod dumpAllReport(rf As migrateiis2apache.RefFindAndReplace, directory As %String) As %Status [ Private ]
 {
 	Set tSc = $$$OK, normalizedDirectory = ##class(%File).NormalizeDirectory(directory)
  	Try{
  		Set ts = $tr($zdt($h,8),"-: ","")
  		$$$TOE(tSc,..dumpJSONtoFile(rf.getFindReportDetail(),normalizedDirectory_"FindReportDetail-"_ts_".json"))
  		$$$TOE(tSc,..dumpJSONtoFile(rf.getFindReportSummary(),normalizedDirectory_"FindReportSummary-"_ts_".json"))
  		$$$TOE(tSc,..dumpJSONtoFile(rf.getReplaceReportDetail(),normalizedDirectory_"ReplaceReportDetail-"_ts_".json"))
  		$$$TOE(tSc,..dumpJSONtoFile(rf.getReplaceReportSummary(),normalizedDirectory_"ReplaceReportSummary-"_ts_".json"))
  	}Catch(ex) {
  		Set tSc = e.AsStatus()
  	}
  	Return tSc
 }
 
 
 ClassMethod dumpJSONtoFile(json As %DynamicObject, filepath As %String) As %Status
 {
 	#dim file As %File
 	Set tSc = $$$OK
 	Try{
 		Set file = ##class(%File).%New(filepath)
 		$$$TOE(tSc,file.Open("WSN"))
 		Do json.%ToJSON(.file)
 		Do file.Flush()
 		Do file.Close()
 	}Catch(ex) {
 		Set tSc = ex.AsStatus()
 	}
 	Return tSc
 }
 
}