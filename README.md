# migrateiis2apache

This is an helper for migrate your webapps to apache.  
The purpose is find and fix all static files references  
if the case is incorrect.  As you know apache and linux filesystem are case sensitive.  
If you're application has been developped and installed on Windows  
and IIS web server, may be you encounter a problem with the case for migrate to apache and docker.  
This tools, check all static references from your webapp directory and fix the correct case in your source files.  


## Install

Clone migrateiis2apache repository.  

## Import Installer

Open a terminal.  

```
Zn "USER"
Do $SYSTEM.OBJ.Load("<repository_path>/src/cls/migrateiis2apache/installer/Installer.cls","ck")
```
## Launch Installer

Simple install in "USER" namespace:

```
Zn "USER"
Set pVars("APPPATH")="<repository_path>"
Do ##class(migrateiis2apache.installer.Installer).normalizeDir(.pVars)
Set tSc = ##class(migrateiis2apache.installer.Installer).setup(.pVars)
Write !,"Install Status : ",$SYSTEM.Status.GetOneErrorText(tSc)
```


## How to use

### Find bad references

Find bad references without repair.

```
Set sourceDir = "<source_to_repair_directory>"	; usually a git directory 
Set webAppDir = "<webapp_directory>" ; web directory contains static files
Set findReportDir = "" ; If set, a find report is written within specified directory.
Set report = ##class(migrateiis2apache.services.RepairCaseServices).findCaseError(sourceDir,webAppDir,,,findReportDir)
```

### Find and repair bad references


```
Set sourceDir = "<source_to_repair_directory>"	; usually a git directory 
Set webAppDir = "<webapp_directory>" ; web directory contains static files
Set findReportDir = "" ; If set, a find report is written within specified directory.
Set report = ##class(migrateiis2apache.services.RepairCaseServices).findAndRepairCaseError(sourceDir,webAppDir,,,findReportDir)
```

## Built With

* Iris for Health 2019.2
* Write $zv : IRIS for UNIX (Ubuntu Server LTS for x86-64 Containers) 2019.2 (Build 109U) Fri Jul 26 2019 09:19:03 EDT
* Version: Photon Release (4.8.0) Build id: 20180619-1200
* Atelier 1.3 (see https://download.intersystems.com/download/atelier.csp for install instructions)

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/elryo/migrateiis2apache/tags). 

## Authors

* **Lorenzo Scalese** - *Initial work* - [elryo](https://github.com/elryo)

See also the list of [contributors](https://github.com/elryo/migrateiis2apache/contributors) who participated in this project.  

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.  

## Acknowledgments

