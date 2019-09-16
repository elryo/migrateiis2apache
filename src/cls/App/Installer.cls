/// source : https://github.com/intersystems-community/objectscript-docker-template/blob/master/Installer.cls
Class App.Installer
{

XData MyInstall [ XMLNamespace = INSTALLER ]
{
<Manifest>
  <Default Name="NAMESPACE" Value="USER"/>
  <Default Name="DBNAME" Value="USER"/>
  <Default Name="APPPATH" Dir="/opt/app/" />
  
  <Default Name="SOURCESPATH" Dir="${APPPATH}src/" />
  <Default Name="RESOURCE" Value="%DB_${DBNAME}" />
  <Default Name="ENSEMBLE" Value="0" />  

  <Default Name="DBDATAPATH" Value="${MGRDIR}"/>
  <Default Name="DBCODEPATH" Value="${MGRDIR}"/>
  
  <If Condition='(##class(Config.Namespaces).Exists("${NAMESPACE}")=0)'>
	  <Namespace Name="${NAMESPACE}" Code="${DBNAME}-CODE" Data="${DBNAME}-DATA" Create="yes" Ensemble="${ENSEMBLE}">
	    <Configuration>
	      <Database Name="${DBNAME}-CODE" Dir="${DBDATAPATH}${DBNAME}-CODE" Create="yes" Resource="${RESOURCE}"/>
	      <Database Name="${DBNAME}-DATA" Dir="${DBCODEPATH}${DBNAME}-DATA" Create="yes" Resource="${RESOURCE}"/>
	    </Configuration>
	  </Namespace>
  </If>

  <Namespace Name="${NAMESPACE}" Create="no">
  	<Import File="${SOURCESPATH}" Recurse="1"/>
  </Namespace>
</Manifest>
}

/*
	Set pVars("NAMESPACE")=""
	Set pVars("DBNAME")=""
	Set pVars("APPPATH")=""
	Set pVars("SOURCESPATH")=""
	Set pVars("RESOURCE")=""
	Set pVars("ENSEMBLE")=""
	Set pVars("DBDATAPATH")=""
	Set pVars("DBCODEPATH")=""
	Do ##class(App.Installer).normalizeDir(.pVars)
	Set tSc = ##class(App.Installer).setup(.pVars)
*/
ClassMethod setup(ByRef pVars, pLogLevel As %Integer = 3, pInstaller As %Installer.Installer, pLogger As %Installer.AbstractLogger) As %Status [ CodeMode = objectgenerator, Internal ]
{ 
	Quit ##class(%Installer.Manifest).%Generate(%compiledclass, %code, "MyInstall")
}

ClassMethod normalizeDir(ByRef pVars) As %Status 
{
	Set:$Data(pVars("APPPATH")) pVars("APPPATH")=##class(%File).NormalizeDirectory(pVars("APPPATH"))
	Set:$Data(pVars("SOURCESPATH")) pVars("SOURCESPATH")=##class(%File).NormalizeDirectory(pVars("SOURCESPATH"))
	Set:$Data(pVars("DBDATAPATH")) pVars("DBDATAPATH")=##class(%File).NormalizeDirectory(pVars("DBDATAPATH"))
	Set:$Data(pVars("DBCODEPATH")) pVars("DBCODEPATH")=##class(%File).NormalizeDirectory(pVars("DBCODEPATH"))
	Return $$$OK
}

}