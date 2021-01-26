:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

@set GameDir=E:\Games\Cyberpunk 2077
@set SevenZipExe=C:\Program Files\7-Zip\7z.exe

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

@set WorkDir=%CD%
@set DistDir=%WorkDir%\dist

@set ModPath=bin\x64\plugins\cyber_engine_tweaks\mods\respector

@findstr /r "[0-9]\.[0-9]\.[0-9]*" "%GameDir%\%ModPath%\mod\Respector.lua" > "%WorkDir%\release.ver"
@set /p Version=<"%WorkDir%\release.ver"
@set Version=%Version:~31,5%
@del /f "%WorkDir%\release.ver" > nul

@set ReleaseZip=%DistDir%\respector-%Version%.zip

@echo Version: %Version%
@echo Release: %ReleaseZip%

@if not exist "%DistDir%" mkdir "%DistDir%"
@if exist "%ReleaseZip%" del /f "%ReleaseZip%"

@cd "%GameDir%"

@"%SevenZipExe%" a -tzip -mx9 ^
	-x!"%ModPath%\.dev\" ^
	-x!"%ModPath%\.git\" ^
	-x!"%ModPath%\.idea\" ^
	-x!"%ModPath%\bin\" ^
	-x!"%ModPath%\dist\" ^
	-x!"%ModPath%\mod\data\*.xlsm" ^
	-x!"%ModPath%\mod\data\tweakdb-names.*" ^
	-x!"%ModPath%\specs\??*.lua" ^
	-x!"%ModPath%\.gitignore" ^
	-x!"%ModPath%\respector.log" ^
	"%ReleaseZip%" ^
	"%ModPath%" ^
	"%ModPath%\specs\V.lua" ^
	> nul

@echo Done.

@cd "%WorkDir%"
