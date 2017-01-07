@echo off
setlocal enableextensions enabledelayedexpansion
	echo git clone -q --branch=PHP-%PHP_REL% https://github.com/php/php-src C:\projects\php-src
	git clone -q --branch=PHP-%PHP_REL% https://github.com/php/php-src C:\projects\php-src

	xcopy %APPVEYOR_BUILD_FOLDER% C:\projects\php-src\ext\win32service\ /s /e /y /f

	xcopy %APPVEYOR_BUILD_FOLDER%\LICENSE %APPVEYOR_BUILD_FOLDER%\artifacts\ /y /f
	xcopy %APPVEYOR_BUILD_FOLDER%\examples %APPVEYOR_BUILD_FOLDER%\artifacts\examples\ /y /f

	cd %APPVEYOR_BUILD_FOLDER%\appveyor
	wget -N --progress=bar:force:noscroll http://windows.php.net/downloads/php-sdk/php-sdk-binary-tools-20110915.zip
	7z x -y php-sdk-binary-tools-20110915.zip -oC:\projects\php-sdk

	for %%a in (%ARCHITECTURES%) do (
		set ARCH=%%a
		if "!ARCH!"=="amd64" set DEPTS_ARCH=x64
		if "!ARCH!"=="x86" set DEPTS_ARCH=x86

		call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall" !ARCH!
		call C:\projects\php-sdk\bin\phpsdk_setvars.bat

		cd %APPVEYOR_BUILD_FOLDER%\appveyor
		wget -N --progress=bar:force:noscroll http://windows.php.net/downloads/php-sdk/deps-%PHP_REL%-vc14-!DEPTS_ARCH!.7z
		7z x -y deps-%PHP_REL%-vc14-!DEPTS_ARCH!.7z -oC:\projects\php-src

		for %%z in (%ZTS_STATES%) do (
			set ZTS_STATE=%%z
			if "!ZTS_STATE!"=="enable" set ZTS_SHORT=ts
			if "!ZTS_STATE!"=="disable" set ZTS_SHORT=nts

			cd C:\projects\php-src

			call buildconf.bat
			call configure.bat --disable-all --with-mp=auto --enable-cli --!ZTS_STATE!-zts --enable-win32service=shared --with-config-file-scan-dir=%APPVEYOR_BUILD_FOLDER%\build\modules.d --with-prefix=%APPVEYOR_BUILD_FOLDER%\build --with-php-build=deps

			nmake
			nmake install

			cd %APPVEYOR_BUILD_FOLDER%
			move build\ext\php_win32service.dll artifacts\php_win32service-%PHP_REL%-vc14-!ZTS_SHORT!-!DEPTS_ARCH!.dll
		)
	)
endlocal