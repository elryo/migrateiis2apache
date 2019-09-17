Class migrateiis2apache.RefFinderRules Extends %RegisteredObject
{
	Property fileReference As %String;
	
	ClassMethod searchInLine(line As %String, fileReference As %String) As %DynamicObject
	{
		Set lowerLine = $Zconvert(line,"l"), lowerFileReference = $Zconvert(fileReference,"l"),
			posEnd = $Find(lowerLine,lowerFileReference)
		If (''posEnd)&&('$Find(line,fileReference)) {
			Set reportLine = { "referenceFound" : ($Extract(line,posEnd-$Length(fileReference),posEnd)), "expected": (fileReference) }
			Return reportLine
		}
		Return 0
	}
	
	ClassMethod searchInFile(filePath As %String, fileReferences As %List)
	{
		Set stream=##class(%Stream.FileCharacter).%New(), tSc = $$$OK, line = 0
		$$$TOE(tSc,stream.LinkToFile(filePath))
		Set reportFile = {
			"filePath":(filePath),
			"referencesError":[]
		}
		While 'stream.AtEnd {
			Set line=stream.ReadLine(), ptr = 0, line = $i(line)
			While ($Listnext(fileReferences,ptr,currentFileRef)) {
				Set reportLine = ..searchInLine(line,currentFileRef)
				Continue:reportLine=0
				Set reportLine.line=line
				Do reportFile.referencesError.%Push(reportLine)
			}
		}
		Kill stream
		Return reportFile
	}
	
	ClassMethod searchInDirectory(sourceDirectory As %String,fileReferences As %List) 
	{
		Do ##class(migrateiis2apache.services.ScanDirectoryServices).recursiveFileList(sourceDirectory,.fileList)
		Set ptr = 0
		Set reportDirectory = []
		While ($Listnext(fileList,ptr,filepath)) {
			Set reportFile = ..searchInFile(filepath,.fileReferences)
			/*:reportFile.referencesError.%Size()>0*/
			Do:reportFile.referencesError.%Size()>0 reportDirectory.%Push(reportFile)
		}
		Return reportDirectory
	}
	
	ClassMethod test() 
	{
		Set l = $lb("/js/jquery/serializeobject/serializeobject.js")
		s json= ..searchInDirectory("/usr/irissys/csp/ALPHACARE/",.l)
		Write json.%ToJSON()
		q ""
	}
}