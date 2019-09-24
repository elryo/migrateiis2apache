Class migrateiis2apache.RefFinderRules
{
	
	Parameter REGEX = "((?:\/[a-zA-Z0-9]+(?:_[a-zA-Z0-9]+)*(?:\-[a-zA-Z0-9]+)*(?:\.[a-zA-Z0-9]+)*)+\.(js|JS|css|CSS|jpg|JPG|png|PNG|gif|GIF|xml|XML|xsl|XSL|jar|JAR|csp|CSP))";
	
	ClassMethod findInLine(line As %String, ByRef fileReference As %Binary,posStart As %Integer = 0) As %DynamicObject
	{
		Set posStart = $Locate(line,..#REGEX,posStart,,pathFound)
		Return:posStart=0 {}
		Set lowerPathFound = $Zconvert(pathFound,"l")
		If ($Data(fileReference(lowerPathFound))&&(fileReference(lowerPathFound)'=pathFound)) {
			; Case problem found
			Return { 
				"reached" : (pathFound), 
				"expected": (fileReference(lowerPathFound)), 
				"posEnd" : (posStart+$Length(pathFound)),
				"posStart" : (posStart)
			}
		}
		Return {}
	}
	
	ClassMethod findInFile(filePath As %String, ByRef fileReferences As %Binary,verbose As %Boolean = 1) As %DynamicObject
	{
		Set stream=##class(%Stream.FileCharacter).%New(), tSc = $$$OK, line = 0, errCount=0
		$$$TOE(tSc,stream.LinkToFile(filePath))
		Set reportFile = {
			"filePath":(filePath),
			"referencesError":[]
		}
		
		While ('stream.AtEnd) {
			Set line=stream.ReadLine(), ptr = 0, lineNumber = $i(lineNumber)
			Set reportLine = ..findInLine(line,.fileReferences)
			While (reportLine.%Size()>0) {
				Set errCount = $Increment(errCount)
				Set reportLine.line=lineNumber
				Do reportFile.referencesError.%Push(reportLine)
				Set posStart = reportLine.posEnd
				Write:verbose !," - reached : ",reportLine.reached, " expected : ",reportLine.expected
				Set reportLine = ..findInLine(line,.fileReferences,posStart)
			}
		}
		Set reportFile.errorCount=errCount
		Kill stream
		Return reportFile
	}
	
	ClassMethod findInDirectory(sourceDirectory As %String, ByRef fileReferences As %Binary, verbose As %Boolean = 1) As %DynamicObject
	{
		Set fileList = ##class(migrateiis2apache.services.ScanDirectoryServices).getSourceFileList(sourceDirectory,.fileList),
		 	ptr = 0,
		 	nbFile = 0,
		 	totalErrorCount=0,
			reportWrap = {
				"sourceDirectory":(sourceDirectory),
				"searchReferences":[],
				"fileAnalyzed":"",
				"totalErrorCount":"",
				"detail":[]
			}
		/*Set searchReferences =[] 
		Set k = $Order(fileReferences(""))
		For  {
			Quit:k=""
			Do reportWrap.searchReferences.%Push(k)
			Set k = $Order(fileReferences(k))
		}*/
		
		Set reportDirectory = []
		While ($Listnext(fileList,ptr,filePath)) {
			Write:verbose !,"[*] Analyse file ",filePath," ..."
			Set reportFile = ..findInFile(filePath,.fileReferences,verbose),
				nbFile=$Increment(nbFile)
			Continue:reportFile.referencesError.%Size()=0
			Do reportDirectory.%Push(reportFile)
		 	Set totalErrorCount = totalErrorCount + reportFile.errorCount
		}
		Do reportWrap.%Set("fileAnalyzed",nbFile,"number"),
		   reportWrap.%Set("detail",reportDirectory),
		   reportWrap.%Set("totalErrorCount",totalErrorCount,"number")
		
		Return reportWrap
	}
	
	ClassMethod replace(findReport As %DynamicObject, verbose As %Boolean = 1) As %Status
	{
		#dim file As %Library.File
		Set replaceReport = {
			"replaceDone":0,
			"replaceError":0,
			"errorsSummary":[]
		}
		Set tSc = $$$OK, 
			iter = findReport.%GetIterator(),
			replaceDone = 0,
			replaceError = 0
		While (iter.%GetNext(.key, .value)) {
			Set filePath = value.filePath, 
				file=##class(%File).%New(filePath),
				errorIter = value.referencesError.%GetIterator()
			Do file.Open("RWS")
			Write:verbose !,"[*] ",filePath
			While (errorIter.%GetNext(.keyErr, .replaceInfo)) {
				Continue:replaceInfo.%Size()=0
				Write:verbose !,$c(9)," - [REPLACE] ", replaceInfo.reached, " BY ", replaceInfo.expected
				Do ..setFileCursor(file,replaceInfo.line,replaceInfo.posStart)
				Set replaceValue = file.Read($Length(replaceInfo.reached)), checkSc = ..checkBeforeReplace(replaceInfo,replaceValue)
				If $$$ISOK(checkSc) {
					Do ..setFileCursor(file,replaceInfo.line,replaceInfo.posStart)
					;Do file.Write(replaceInfo.expected)
					Set replaceDone = $Increment(replaceDone)
					Write:verbose !,$c(9,9),"Status : OK"
					Set replaceInfo.replaceStatus="OK"
				}Else{
					Write:verbose !,$c(9,9),$SYSTEM.Status.GetOneErrorText(checkSc), " reached value ",replaceValue
					Set replaceError = $Increment(replaceError)
					Set replaceInfo.replaceStatus=$SYSTEM.Status.GetOneErrorText(checkSc)
					Do replaceReport.errorsSummary.%Push(replaceInfo)
				}
			}
			Set replaceReport.replaceDone=replaceDone, replaceReport.replaceError=replaceError
			Do file.Flush(), file.Close()
			Kill file
		}
		Return $$$OK
	}
	
	ClassMethod setFileCursor(file As %File, line As %Integer, pos As %Integer) 
	{
		Do file.Rewind()
		For i=1:1:line-1 Do file.ReadLine()
		Do file.Read(pos-1)
	}
	
	ClassMethod checkBeforeReplace(replaceInfo As %DynamicObject, replaceValue As %String) As %Status
	{
		Return:($Length(replaceInfo.reached)'=$Length(replaceInfo.expected)) $$$ERROR(5001,"Replace size error")
		Return:(replaceValue'=replaceInfo.reached) $$$ERROR(5001,"Replace value error, may be an offset error")
		Return $$$OK
	}
	
	
	ClassMethod test(
		webFilesDir As %String = "/usr/irissys/csp/ALPHACARE/",
		sourceFilesDir As %String = "/usr/irissys/csp/ALPHACARE/",
		reportFile As %String = "/xcare/databases/replace-report.json"
		) As %DynamicObject
	{
		;Set l = $lb("/js/jquery/serializeobject/serializeobject.js")
		Set l = ##class(migrateiis2apache.services.ScanDirectoryServices).getWebFilesList(webFilesDir), ptr=0
		While ($listnext(l,ptr,v)) {
			Set ref($zcvt(v,"l"))=v
		}
		Set report = ..findInDirectory(sourceFilesDir,.ref,1)
		Do ..replace(report.detail,1)
		Set file = ##class(%File).%New(reportFile)
		Do file.Open("WSN")
		Do report.%ToJSON(.file)
		;Set tSc = ..replace(json,1)
		Return report
	}
	
	
}