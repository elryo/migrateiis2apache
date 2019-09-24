Class migrateiis2apache.services.ScanDirectoryServices
{
	ClassMethod getWebFilesList(
		webFilesDirectory As %String,
		wildcards As %String = {"*.js;*.css;*.jpg;*.png;*.gif;*.xml;*.xsl;*.jar;*.csp;*.csr;*.html;*.htm;*.pdf"}) As %List
	{
		Do ..recursiveFileList(webFilesDirectory,.list,wildcards)
		Set ptr = 0, rList = ""
		While ($Listnext(list,ptr,value)) {
			;w value,!
			Set $List(rList,$Listlength(rList)+1)=..getRelativePath(webFilesDirectory,value)
		}
		Return rList
	}
	
	ClassMethod getSourceFileList(
		sourceFileDirectory As %String,
		wildcards As %String = { "*.js;*.css;*.xml;*.xsl;*.csp;*.csr;*.html;*.htm" }) As %List
	{
		Do ..recursiveFileList(sourceFileDirectory,.list,wildcards)
		Return list
	}
	
	ClassMethod recursiveFileList(directory As %String, fileList As %List = { "" }, wildcards As %String="*") As %Status
	{
		Set tSqlStatement = ##class(%SQL.Statement).%New(),
		    tSc = tSqlStatement.%PrepareClassQuery("%File","FileSet")
		Return:$$$ISERR(tSc) tSc
		Set tResult = tSqlStatement.%Execute(directory,wildcards,,1)
		While (tResult.%Next()) {
			If (tResult.%Get("Type")="D") {
				Set tSc = ..recursiveFileList(tResult.%Get("Name"),.fileList,.wildcards)
				Return:$$$ISERR(tSc) tSc
			} Else {
				Set $List(fileList,$Listlength(fileList)+1)=tResult.%Get("Name")
			}
		}
		Kill tSqlStatement,tResult
		Return tSc
	}
	
	ClassMethod getRelativePath(webFilesDirectory As %String,fileName As %String) As %String
	{
		Set normalizedDir = ##class(%File).NormalizeDirectory(webFilesDirectory)
		Return $Extract(fileName,$Length(normalizedDir),*)
	}
}