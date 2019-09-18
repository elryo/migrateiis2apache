Class migrateiis2apache.RefFinderRules
{
	
	ClassMethod findInLine(line As %String, fileReference As %String) As %DynamicObject
	{
		Set lowerLine = $Zconvert(line,"l"), lowerFileReference = $Zconvert(fileReference,"l"),
			posEnd = $Find(lowerLine,lowerFileReference)
		Return:(''posEnd)&&('$Find(line,fileReference)) { 
			"reached" : ($Extract(line,posEnd-$Length(fileReference),posEnd-1)), 
			"expected": (fileReference), 
			"posEnd" : (posEnd-1),
			"posStart" : (posEnd-1-$Length(fileReference))
		}
		Return {}
	}
	
	ClassMethod findInFile(filePath As %String, fileReferences As %List,verbose As %Boolean = 1) As %DynamicObject
	{
		Set stream=##class(%Stream.FileCharacter).%New(), tSc = $$$OK, line = 0
		$$$TOE(tSc,stream.LinkToFile(filePath))
		Set reportFile = {
			"filePath":(filePath),
			"referencesError":[]
		}
		While ('stream.AtEnd) {
			Set line=stream.ReadLine(), ptr = 0, lineNumber = $i(lineNumber)
			While ($Listnext(fileReferences,ptr,currentFileRef)) {
				Write:verbose !,$c(9),"[CHECK REF] ",currentFileRef," ..."
				Set reportLine = ..findInLine(line,currentFileRef)
				Continue:reportLine.%Size()=0
				Set reportLine.line = lineNumber
				Do reportFile.referencesError.%Push(reportLine)
			}
		}
		Kill stream
		Return reportFile
	}
	
	ClassMethod findInDirectory(sourceDirectory As %String,fileReferences As %List, verbose As %Boolean = 1) As %DynamicObject
	{
		Do ##class(migrateiis2apache.services.ScanDirectoryServices).recursiveFileList(sourceDirectory,.fileList)
		Set ptr = 0
		Set reportDirectory = []
		While ($Listnext(fileList,ptr,filePath)) {
			Write:verbose !,"[*] Analyse file ",filePath," ..."
			Set reportFile = ..findInFile(filePath,.fileReferences)
			Do:reportFile.referencesError.%Size()>0 reportDirectory.%Push(reportFile)
		}
		Return reportDirectory
	}
	
	ClassMethod replace(findReport As %DynamicObject, verbose As %Boolean = 1) As %Status
	{
		#dim file As %Library.File
		Set tSc = $$$OK, iter = findReport.%GetIterator()
		While (iter.%GetNext(.key, .value)) {
			Set filePath = value.filePath, file=##class(%File).%New(filePath)
			Do file.Open("RWS")
			Set errorIter = value.referencesError.%GetIterator()
			Write:verbose !,"[*] ",filePath
			While (errorIter.%GetNext(.keyErr, .replaceInfo)) {
				Continue:replaceInfo.%Size()=0
				Write:verbose !,$c(9)," - [REPLACE] ", replaceInfo.reached, " BY ", replaceInfo.expected
				Do ..setFileCursor(file,replaceInfo.line,replaceInfo.posStart)
				Set replaceValue = file.Read($Length(replaceInfo.reached)), checkSc = ..checkBeforeReplace(replaceInfo,replaceValue)
				If $$$ISOK(checkSc) {
					Do ..setFileCursor(file,replaceInfo.line,replaceInfo.posStart)
					Do file.Write(replaceInfo.expected)
					Write:verbose !,$c(9,9),"Status : OK"
				}Else{
					Write:verbose !,$c(9,9),$SYSTEM.Status.GetOneErrorText(checkSc), " reached value ",replaceValue
				}
			}
			Do file.Flush()
			Do file.Close()
			Kill file
		}
		Return $$$OK
	}
	
	ClassMethod setFileCursor(file As %File, line As %Integer, pos As %Integer) 
	{
		Do file.Rewind()
		For i=1:1:line-1 Do file.ReadLine()
		Do file.Read(pos)
	}
	
	ClassMethod checkBeforeReplace(replaceInfo As %DynamicObject, replaceValue As %String) As %Status
	{
		Return:($Length(replaceInfo.reached)'=$Length(replaceInfo.expected)) $$$ERROR(5001,"Replace size error")
		Return:(replaceValue'=replaceInfo.reached) $$$ERROR(5001,"Replace value error, may be an offset error")
		Return $$$OK
	}
	
	ClassMethod test() 
	{
		;Set l = $lb("/js/jquery/serializeobject/serializeobject.js")
		Set l = ##class(migrateiis2apache.services.ScanDirectoryServices).getWebFilesList("/databases/Csp/")
		Set json = ..findInDirectory("/databases/Csp/",.l)
		Set tSc = ..replace(json,1)
		q ""
	}
	
	
}