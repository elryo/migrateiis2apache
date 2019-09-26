Class migrateiis2apache.RefFindAndReplace Extends %RegisteredObject
{
 
 /// Headache...
 Parameter REGEX = "(\/([A-z0-9-_\.+])*)+\.(js|JS|css|CSS|jpg|JPG|png|PNG|gif|GIF|xml|XML|xsl|XSL|jar|JAR|csp|CSP)";
 
 Parameter WILDCARDSWEBFILES = "*.js;*.css;*.jpg;*.png;*.gif;*.xml;*.xsl;*.jar;*.csp;*.csr;*.html;*.htm;*.pdf;*.JS;*.CSS;*.JPG;*.PNG;*.GIF;*.XML;*.XSL;*.JAR;*.CSP;*.CSR;*.HTML;*.HTM;*.PDF";
 
 Parameter WILDCARDSSOURCEFILES = "*.js;*.css;*.xml;*.xsl;*.csp;*.csr;*.html;*.htm;*.JS;*.CSS;*.XML;*.XSL;*.CSP;*.CSR;*.HTML;*.HTM";
 
 Property findReportDetail As %DynamicObject [ Private ];
 
 Property findReportSummary As %DynamicObject  [ Private ];
 
 Property replaceReportDetail As %DynamicObject  [ Private ];
 
 Property replaceReportSummary As %DynamicObject  [ Private ];
 
 Property fileReferences [ Multidimensional ];
 
 Property verbose As %Boolean [ InitialExpression = 1 ];
 
 /// Web app file directory to scan.
 Property webFileDirectory As %String [ Private ];
 
 /// Source file directory to apply a find and replace (git directory)
 Property sourceDirectory As %String [ Private ];
 
 /// Regex used for extract path from source file <br/>
 Property regex As %String [ InitialExpression = { ..#REGEX } ];
 
 Property wildCardsWebFiles As %String [ InitialExpression = { ..#WILDCARDSWEBFILES } ];
 
 Property wildCardsSourceFiles As %String [ InitialExpression = { ..#WILDCARDSSOURCEFILES } ];
 
 Method %OnNew(webFileDirectory As %String, sourceDirectory As %String, verbose As %Boolean = 1) As %Status
 {
 	Set ..webFileDirectory = webFileDirectory, ..sourceDirectory = sourceDirectory, ..verbose = verbose
  	Return $$$OK
 }
 
 /// Perform a search of all "case" mistake in source code directory <br/>
 Method find() As %Status
 {
 	Set tSc = $$$OK
 	Try{
 		Do ..reset()
 		$$$TOE(tSc,..initializePossibleMistake())
 		$$$TOE(tSc,..findInSourceDirectory())
 	}Catch(ex){
 		Set tSc = ex.AsStatus()
 	}
 	Return tSc
 }
 
 Method initializePossibleMistake() As %Status [ Private ]
 {
  	Set tSc = $$$OK
  	Try{
	  	Set l = ##class(migrateiis2apache.services.ScanDirectoryServices).getWebFilesList(..webFileDirectory,..wildCardsWebFiles), ptr=0
		While ($Listnext(l,ptr,v)) {
			Set i%fileReferences($zcvt(v,"l"))=v
		}
	}Catch(ex){
		Set tSc = ex.AsStatus()
	}
  	Return tSc
 }
 
 /// Perfom a replace of all "case" mistake by the expected value <br/>
 Method replace() As %Status
 {
 	Set tSc = $$$OK
 	Try{
	 	#dim file As %Library.File
		Set ..replaceReportDetail = {
				"replaceToDo":(..findReportDetail.totalErrorCount),
				"replaceDone":0,
				"replaceError":0,
				"errorsSummary":[],
				"replaceDoneSummary":[]
			},
			..replaceReportSummary = {
				"replaceToDo":(..findReportDetail.totalErrorCount),
				"replaceDone":0,
				"replaceError":0
			},
			tSc = $$$OK, 
			iter = ..findReportDetail.reportDirectory.%GetIterator(),
			replaceDone = 0,
			replaceError = 0
		While (iter.%GetNext(.key, .value)) {
			Set filePath = value.filePath, 
				file=##class(%File).%New(filePath),
				errorIter = value.referencesError.%GetIterator()
			Do file.Open("RWS")
			Write:..verbose !,"[*] ",filePath
			While (errorIter.%GetNext(.keyErr, .replaceInfo)) {
				Continue:replaceInfo.%Size()=0
				Write:..verbose !,$c(9)," - [REPLACE] ", replaceInfo.reached, " BY ", replaceInfo.expected
				Do ..setFileCursor(file,replaceInfo.line,replaceInfo.posStart)
				Set replaceValue = file.Read($Length(replaceInfo.reached)), checkSc = ..checkBeforeReplace(replaceInfo,replaceValue)
				If $$$ISOK(checkSc) {
					Do ..setFileCursor(file,replaceInfo.line,replaceInfo.posStart)
					Do file.Write(replaceInfo.expected)
					Set replaceDone = $Increment(replaceDone)
					Write:..verbose !,$c(9,9),"Status : OK"
					Do ..replaceReportDetail.replaceDoneSummary.%Push({}.%FromJSON(replaceInfo.%ToJSON()).%Set("replaceStatus",$SYSTEM.Status.GetOneErrorText(checkSc)))
				}Else{
					Write:..verbose !,$c(9,9),$SYSTEM.Status.GetOneErrorText(checkSc), " reached value ",replaceValue
					Set replaceError = $Increment(replaceError)
					Do ..replaceReportDetail.errorsSummary.%Push({}.%FromJSON(replaceInfo.%ToJSON()).%Set("replaceStatus",$SYSTEM.Status.GetOneErrorText(checkSc)))
				}
			}
			
			Set ..replaceReportDetail.replaceDone=replaceDone, ..replaceReportDetail.replaceError=replaceError,
				..replaceReportSummary.replaceDone=replaceDone, ..replaceReportSummary.replaceError=replaceError
			
			Do file.Flush(), file.Close()
			Kill file
		}
	}Catch(ex) {
		Set tSc = ex.AsStatus()
	}
	Return tSc
 }
 
 Method findAndReplace() As %Status
 {
 	Set tSc = $$$OK
 	Try{
	 	$$$TOE(tSc,..find())
	 	$$$TOE(tSc,..replace())
 	}Catch(ex) {
 		Set tSc = ex.AsStatus()
 	}
 	Return tSc
 }
 
 Method reset() [ Private ]
 {
  	Set ..findReportDetail = {}, ..findReportSummary = {}, ..replaceReportDetail = {}, ..replaceReportSummary = {}
  	Kill i%fileReferences
  	Return
 }
 
 ClassMethod setFileCursor(ByRef file As %File, line As %Integer, pos As %Integer) As %Status [ Private ]
 {
 	Set tSc = $$$OK
 	Try{
		Do file.Rewind()
		For i=1:1:line-1 Do file.ReadLine()
		Do file.Read(pos-1)
	}Catch(ex) {
		Set tSc = $$$OK
	}
	Return tSc
 }
 
 ClassMethod checkBeforeReplace(replaceInfo As %DynamicObject, replaceValue As %String) As %Status [ Private ]
 {
	Return:($Length(replaceInfo.reached)'=$Length(replaceInfo.expected)) $$$ERROR(5001,"Replace size error")
	Return:(replaceValue'=replaceInfo.reached) $$$ERROR(5001,"Replace value error, may be an offset error")
	Return $$$OK
 }
 
 Method findInSourceDirectory() As %Status
 {
 	Set tSc = $$$OK
 	Try {
		Set fileList = ##class(migrateiis2apache.services.ScanDirectoryServices).getSourceFileList(..sourceDirectory,..wildCardsSourceFiles),
		 	ptr = 0, nbFile = 0, totalErrorCount=0, reportDirectory = [],
		 	..findReportSummary = {
				"sourceDirectory" : (..sourceDirectory),
				"webFileDirectory" : (..webFileDirectory),
				"nbAnalyzedFile" : 0,
				"totalErrorCount" : 0
			}
		While ($Listnext(fileList,ptr,filePath)) {
			Write:..verbose !,"[*] Analyse file ",filePath," ..."
			Set reportFile = ..findInFile(filePath), nbFile = $Increment(nbFile)
			Continue:reportFile.referencesError.%Size()=0
			Do reportDirectory.%Push(reportFile)
		 	Set totalErrorCount = totalErrorCount + reportFile.errorCount
		}
		Do ..findReportSummary.%Set("nbAnalyzedFile",nbFile,"number"), ..findReportSummary.%Set("totalErrorCount",totalErrorCount,"number")
		Set ..findReportDetail = {}.%FromJSON(..findReportSummary.%ToJSON()) //initialize with summary report
		Do ..findReportDetail.%Set("checkedReferences",..dynRef()), ..findReportDetail.%Set("reportDirectory",reportDirectory)
	}Catch(ex) {
		Set tSc = ex.AsStatus()
	}
	Return tSc
 }
 
 Method findInFile(filePath As %String) As %DynamicObject
 {
	Set stream=##class(%Stream.FileCharacter).%New(), tSc = $$$OK, line = 0, errCount=0
	$$$TOE(tSc,stream.LinkToFile(filePath))
	Set reportFile = {
		"filePath":(filePath),
		"referencesError":[]
	}
	
	While ('stream.AtEnd) {
		Set line=stream.ReadLine(), ptr = 0, lineNumber = $i(lineNumber)
		Set reportLine = ..findInLine(.line)
		While (reportLine.%Size()>0) {
			Set errCount = $Increment(errCount)
			Set reportLine.line=lineNumber
			Do reportFile.referencesError.%Push(reportLine)
			Set posStart = reportLine.posEnd
			Write:..verbose !," - reached : ",reportLine.reached, " expected : ",reportLine.expected
			Set reportLine = ..findInLine(line,posStart)
		}
	}
	Set reportFile.errorCount=errCount
	Kill stream
	Return reportFile
 }
 
 Method findInLine(line As %String, posStart As %Integer = 0) As %DynamicObject
 {
	Set posStart = $Locate(line,..regex,posStart,,pathFound)
	Return:posStart=0 {}
	Set lowerPathFound = $Zconvert(pathFound,"l")
	If ($Data(i%fileReferences(lowerPathFound))&&(i%fileReferences(lowerPathFound)'=pathFound)) {
		; Case problem found
		Return { 
			"reached" : (pathFound), 
			"expected": (i%fileReferences(lowerPathFound)), 
			"posEnd" : (posStart+$Length(pathFound)),
			"posStart" : (posStart)
		}
	}
	Return {}
 }
 
 Method dynRef() As %DynamicArray [ Private ]
 {
 	Set array = []
	Set k = $Order(i%fileReferences(""))
	For  {
		Quit:k=""
		Do array.%Push(k)
		Set k = $Order(i%fileReferences(k))
	}
	Return array
 }
 
 Method getFindReportSummary() As %DynamicObject
 {
 	Return {}.%FromJSON(..findReportSummary.%ToJSON())	; return a copy of ..findReportSummary
 }
 
 Method getFindReportDetail() As %DynamicObject
 {
 	Return {}.%FromJSON(..findReportDetail.%ToJSON())	; return a copy of ..findReportDetail
 }
 
 Method getReplaceReportSummary() As %DynamicObject
 {
 	Return {}.%FromJSON(..replaceReportSummary.%ToJSON())	; return a copy of ..replaceReportSummary
 }
 
 Method getReplaceReportDetail() As %DynamicObject
 {
 	Return {}.%FromJSON(..replaceReportDetail.%ToJSON())	; return a copy of ..replaceReportDetail
 }
  
}