Class migrateiis2apache.services.ScanDirectoryServices
{
	ClassMethod getWebFilesList(webFilesDirectory As %String) As %List
	{
		Do ..recursiveFileList(webFilesDirectory,.list)
		Return list
	}
	
	ClassMethod recursiveFileList(directory As %String, fileList As %List = { "" }) As %Status
	{
		Set tSqlStatement = ##class(%SQL.Statement).%New(),
		    tSc = tSqlStatement.%PrepareClassQuery("%File","FileSet")
		Return:$$$ISERR(tSc) tSc
		Set tResult = tSqlStatement.%Execute(directory)
		;Do tResult.%Display()
		While (tResult.%Next()) {
			If (tResult.%Get("Type")="D") {
				;Write tResult.%Get("Name"),!
				Set tSc = ..recursiveFileList(tResult.%Get("Name"),.fileList)
				Return:$$$ISERR(tSc) tSc
			}Else{
				Set $List(fileList,$Listlength(fileList)+1)=tResult.%Get("Name")
			}
		}
		Kill tSqlStatement,tResult
		Return tSc
	}
	
	ClassMethod getRelativePath(webFilesDirectory As %String,fileName As %String) As %String
	{
		Set normalizedDir = ##class(%File).NormalizeDirectory(webFilesDirectory)
		Return "."_$Extract(fileName,$Length(normalizedDir),*)
	}
}