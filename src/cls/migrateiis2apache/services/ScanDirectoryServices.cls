Class migrateiis2apache.services.ScanDirectoryServices
{
	ClassMethod getWebFilesList(webFilesDirectory As %String) As %List
	{
		Do ..recursiveFileList(webFilesDirectory,.list)
		Return list
	}
	
	ClassMethod recursiveFileList(directory As %String, fileList As %List = { "" })
	{
		Set tSc = $$$OK, tSqlStatement = ##class(%SQL.Statement).%New()
		$$$TOE(tSc,tSqlStatement.%PrepareClassQuery("%File","FileSet"))
		Set tResult = tSqlStatement.%Execute(directory)
		;Do tResult.%Display()
		While (tResult.%Next()) {
			If (tResult.%Get("Type")="D") {
				Write tResult.%Get("Name"),!
				Do ..recursiveFileList(tResult.%Get("Name"),.fileList)
			}Else{
				Set $List(fileList,$Listlength(fileList)+1)=tResult.%Get("Name")
			}
		}
		Return
	}
	
	ClassMethod getRelativePath(webFilesDirectory As %String,fileName As %String) As %String
	{
		Set normalizedDir = ##class(%File).NormalizeDirectory(webFilesDirectory)
		Return "."_$Extract(fileName,$Length(normalizedDir),*)
	}
}