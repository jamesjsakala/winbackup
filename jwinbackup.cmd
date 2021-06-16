@echo off
setlocal enabledelayedexpansion

REM ###########################################################################################
REM # Author : James Sakala [jamesjsakala@gmail.com]
REM # Date : 17 Jan 2020
REM # Version : 0.0.0.6 Alpha
REM # Purpose : Backup MSSQL DB's;Net COnfig;Registry & Sync Dirs to SAMBA SHARE on Win Boxes
REM #         : This is A Light-Weight Version utilising CMD 99% and Once Powershell  
REM # Updated : 18 Feb 2020 , Added Active Directory IFM and MySQL Backup Ability
REM # Updated : 20 02 2020 fix Timestamp By Using Unix Utils "date" not whacked dos "date/time".
REM # Updated : 26 02 2020 fix folder creation errors by testing existance if errorlevel is !0
REM # Updated : 27 02 2020 Added Keeping Single Local copy of MSSQL DB backups , Functionality
REM # Updated : 03 03 2020 Killed cleanup Bug in old backups command
REM # Updated : 05 03 2020 Killed Another Cleanup Bug. Hope its Dead Now !
REM ###########################################################################################
REM # NOTE : Ensure Script Runs with user privileges with sufficients rights(yes even as cron)
REM ###########################################################################################

SET HostNameDbInstance=SERVER1\MSSQLSERVER
SET DBList=C:\JBACKUP\DBsToBackUp.txt
SET PathsToSync=C:\JBACKUP\PathsToSyncUp.txt
SET LogFile=C:\JBACKUP\jwinbackup.log
SET SMBShare="\\192.168.56.100\backups"
SET MySQLDbUser=root
SET MySQLDbUserPass=<mySQLDBUser>
SET mysqldump="C:\xampp\mysql\bin\mysqldump.exe"
SET MySQLDataDir="C:\xampp\mysql\data"
SET 7zip="C:\JBACKUP\7z\x32\7za.exe"
SET MySQLDBList=C:\JBACKUP\MySQLDBsToBackUp.txt
SET DBMaxDays=-8
SET DBTEMPDIR=C:\DBBACKUPTEST
SET SMBMountDrive="K:"
SET NetBakDBDir=K:\SERVER1\MSSQL
SET NetBakDataDir=K:\SERVER1\Data
SET NetBakMySQLDir=K:\SERVER1\MYSQL
SET NetBakDir=K:\SERVER1\Net
SET NetRegBakDir=K:\SERVER1\Reg
SET NetIFMBakDir=K:\SERVER1\AD\IFM
SET LocalBackupDir=C:\BACKUPS
SET BackUpMsSQL=1
SET BackUpNetConf=1
SET BackUpReg=1
SET SyncFiles=1
SET BackUpAD=0
SET BackUpMySQL=0
SET UseLocalBackups=1


for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestamp=%timestamp%%%i )
ECHO [!timestamp!] ----------------------------------------------------------------------- >> %LogFile%


REM ##############################Mount SMB DRIVE###############################
for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampa=%timestampa%%%i )
NET USE %SMBMountDrive%  %SMBShare%  > nul
IF %errorlevel% == 0 (
	ECHO [!timestampa!] - Mounting: %SMBShare% on %SMBMountDrive% ..... [DONE] >> %LogFile%
) else (
	ECHO [!timestampa!] - Mounting: %SMBShare% on %SMBMountDrive% ..... [FAILED] >> %LogFile%
)
REM #############################################################################

REM ########Backup each database,prepending the date to the filename############
IF %BackUpMsSQL% == 1 (
	IF NOT EXIST %DBTEMPDIR% ( 
		for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampb=%timestampb%%%i )
		MKDIR %DBTEMPDIR%
		IF %errorlevel% == 0 (
			ECHO [!timestampb!] - Creating Directory %DBTEMPDIR% ..... [DONE] >> %LogFile%
			ATTRIB +h %DBTEMPDIR%
			IF %errorlevel% == 0 (
				ECHO [!timestampb!] - Hiding Directory %DBTEMPDIR% ..... [DONE] >> %LogFile%
			) else (
				ECHO [!timestampb!] - Hiding Directory %DBTEMPDIR% ..... [FAILED] >> %LogFile
			)
		) else (
			IF EXIST %DBTEMPDIR% (
				ECHO [!timestampb!] - Creating Directory %DBTEMPDIR% ..... [DONE] >> %LogFile%
			) else (
				ECHO [!timestampb!] - Creating Directory %DBTEMPDIR% ..... [FAILED] >> %LogFile%
			)
		)
	)

	for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampz=%timestampz%%%i )
	IF NOT EXIST %NetBakDBDir% ( 
		MKDIR %NetBakDBDir%
		IF %errorlevel% == 0 (
			ECHO [!timestampz!] - Creating Directory %NetBakDBDir% ..... [DONE] >> %LogFile%
		) else (
			IF EXIST %NetBakDBDir% (
				ECHO [!timestampz!] - Creating Directory %NetBakDBDir% ..... [DONE] >> %LogFile%
			) else (
				ECHO [!timestampz!] - Creating Directory %NetBakDBDir% ..... [FAILED] >> %LogFile%
			)
		)
	)

	REM # Wipe all local backups first
	IF %UseLocalBackups% == 1 (
		IF EXIST "%LocalBackupDir%" (
			DEL "%LocalBackupDir%\*.bak" /Q /F  >nul
			ECHO [!timestampz!] - Cleaning Up "%LocalBackupDir%\" ..... [INFO] >> %LogFile%
		)
	)

	IF EXIST %DBList% (
		FOR /F "tokens=*" %%I IN (%DBList%) DO (
			for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampx=%timestampx%%%i )
			sqlCmd -E -S %HostNameDbInstance% -Q "BACKUP DATABASE [%%I] TO Disk='%DBTEMPDIR%\%%I_Backup!timestampx!.bak'" > nul
			IF EXIST "%DBTEMPDIR%\%%I_Backup!timestampx!.bak" (
				ECHO [!timestampx!] - Backing up database: %%I ..... [DONE] >> %LogFile%
				REM ##################Upload DB Backed Up IF back was Good####################
				COPY  "%DBTEMPDIR%\%%I_Backup!timestampx!.bak"  "%NetBakDBDir%\" /Y /L
				IF %errorlevel% == 0 (
					for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampc=%timestampc%%%i )
					ECHO [!timestampc!] - Uploading  "%DBTEMPDIR%\%%I_Backup!timestampx!.bak" to "%NetBakDBDir%\" ..... [DONE] >> %LogFile%
					REM ##################Remove/Move Created DB File If Upload was OK ####################
					for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampd=%timestampd%%%i )
					IF %UseLocalBackups% == 1 (
						IF EXIST "%LocalBackupDir%" (
							MOVE /Y "%DBTEMPDIR%\%%I_Backup!timestampx!.bak"  "%LocalBackupDir%\"  >nul
							IF %errorlevel% == 0 (
								ECHO [!timestampd!] - Moving   "%DBTEMPDIR%\%%I_Backup!timestampx!.bak" to "%LocalBackupDir%\%%I_Backup!timestampx!.bak" ..... [DONE] >> %LogFile%
							) else (
								ECHO [!timestampd!] - Moving   "%DBTEMPDIR%\%%I_Backup!timestampx!.bak" to "%LocalBackupDir%\%%I_Backup!timestampx!.bak" ..... [FAILED] >> %LogFile%							
								DEL  "%DBTEMPDIR%\%%I_Backup!timestampx!.bak" /Q /F  > nul
							)
							REM ##################Remove Created DB File If Upload was OK ####################
						) else (
							DEL  "%DBTEMPDIR%\%%I_Backup!timestampx!.bak" /Q /F  > nul
							IF %errorlevel% == 0 (
								ECHO [!timestampd!] - Deleting  "%DBTEMPDIR%\%%I_Backup!timestampx!.bak" ..... [DONE] >> %LogFile%
							) else (
								ECHO [!timestampd!] - Deleting  "%DBTEMPDIR%\%%I_Backup!timestampx!.bak" ..... [FAILED] >> %LogFile%
							)
							REM ##################Remove Created DB File If Upload was OK ####################
						)
					) else (
						DEL  "%DBTEMPDIR%\%%I_Backup!timestampx!.bak" /Q /F  > nul
						IF %errorlevel% == 0 (
							ECHO [!timestampd!] - Deleting  "%DBTEMPDIR%\%%I_Backup!timestampx!.bak" ..... [DONE] >> %LogFile%
						) else (
							ECHO [!timestampd!] - Deleting  "%DBTEMPDIR%\%%I_Backup!timestampx!.bak" ..... [FAILED] >> %LogFile%
						)
						REM ##################Remove Created DB File If Upload was OK ####################
					)
				) else (
					REM ############Upload Failed , Keep Local Copy ##########
					for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampe=%timestampe%%%i )
					ECHO [!timestampe!] - Uploading  "%DBTEMPDIR%\%%I_Backup_!timestampx!.bak" to "%NetBakDBDir%\" ..... [FAILED] >> %LogFile%
					ECHO [!timestampe!] - NOTICE  "%DBTEMPDIR%\%%I_Backup_!timestampx!.bak" Will Be Kept ..... [INFO] >> %LogFile%
					REM ############Upload Failed , Keep Local Copy ##########
				)
			) else (
				for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampf=%timestampf%%%i )
				ECHO [!timestampx!] - Backing up database: %%I .....  ..... [FAILED] >> %LogFile%
			)
		)
	)
	REM ###################DELETE OLD DB FILES#############################
	FORFILES /D %DBMaxDays% /P "%NetBakDBDir%" /M *.bak /C "cmd /c del /F /Q /S @path" >nul
	for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampg=%timestampg%%%i )
	ECHO [!timestampg!] - Cleaning Up Old Backup DB Files  in "%NetBakDBDir%\" ..... [INFO] >> %LogFile%
	REM ###################################################################
)

REM ################BACKUP MYSQL ############################
IF %BackUpMySQL% == 1 (
	IF EXIST "C:\xampp\mysql\bin\mysqldump.exe" (
		IF NOT EXIST %NetBakMySQLDir% ( 
			for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampxxy=%timestampxxy%%%i )
			MKDIR %NetBakMySQLDir%
			IF %errorlevel% == 0 (
				ECHO [!timestampxxy!] - Creating Directory %NetBakMySQLDir% ..... [DONE] >> %LogFile%
			) else (
				IF EXIST %NetBakMySQLDir% (
					ECHO [!timestamphxxy!] - Creating Directory %NetBakMySQLDir% ..... [DONE] >> %LogFile%
				) else (
					ECHO [!timestamphxxy!] - Creating Directory %NetBakMySQLDir% ..... [FAILED] >> %LogFile%
				)
			)
		)
	
		IF EXIST %MySQLDBList% (
			FOR /F "tokens=*" %%I IN (%MySQLDBList%) DO (
				for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampxx=%timestampxx%%%i )
				"C:\xampp\mysql\bin\mysqldump.exe" --host="localhost" --user=%MySQLDbUser% --single-transaction --add-drop-table --databases %%I --databases %%I > "%NetBakMySQLDir%\%%I_Backup!timestampxx!.sql" 
				IF %errorlevel% == 0 (
					ECHO [!timestampxx!] - Backing up MySQL Database: %%I ..... [DONE] >> %LogFile%
				) else (
					ECHO [!timestampxx!] - Backing up MySQL Database: %%I ..... [FAILED] >> %LogFile%
				)
			)
		)
	) else (
		for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampxxz=%timestampxxz%%%i )
		ECHO [!timestampxxz!] - XAMP is Probably Not Installed , Check Config ..... [INFO] >> %LogFile%
	)
	REM ###################DELETE OLD DB FILES#############################
	FORFILES /D %DBMaxDays% /P "%NetBakMySQLDir%" /M *.sql /C "cmd /c del /F /Q /S @path" >nul
	for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampxxx=%timestampxxx%%%i )
  	ECHO [!timestampxxx!] - Cleaning Up Old MySQL Backup DB Files  in "%NetBakMySQLDir%\" ..... [INFO] >> %LogFile%
  	REM ###################################################################
)
REM ################BACKUP MYSQL #############################


REM ######Backup Network Settings ###############
IF %BackUpNetConf% == 1 (
	IF NOT EXIST %NetBakDir% ( 
		for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestamph=%timestamph%%%i )
		MKDIR %NetBakDir%
		IF %errorlevel% == 0 (
			ECHO [!timestamph!] - Creating Directory %NetBakDir% ..... [DONE] >> %LogFile%
		) else (
			IF EXIST %NetBakDir% (
				ECHO [!timestamph!] - Creating Directory %NetBakDir% ..... [DONE] >> %LogFile%
			) else ( 
				ECHO [!timestamph!] - Creating Directory %NetBakDir% ..... [FAILED] >> %LogFile%
			)
		)
	)

	IF EXIST %NetBakDir% (
		for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampi=%timestampi%%%i )
		ipconfig /all > "%NetBakDir%\NetworkSettingsBackup_!timestampi!.txt"
		IF EXIST "%NetBakDir%\NetworkSettingsBackup_!timestampi!.txt" (
			ECHO [!timestampi!] - Backing Up Network Settings to "%NetBakDir%\NetworkSettingsBackup_!timestampi!.txt" ..... [DONE] >> %LogFile%
		) else (
			ECHO [!timestampi!] - Backing Up Network Settings to "%NetBakDir%\NetworkSettingsBackup_!timestampi!.txt" ..... [FAILED] >> %LogFile%
		)
	)
	
	for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampj=%timestampj%%%i )
	FORFILES /D %DBMaxDays% /P "%NetBakDir%" /M *.txt /C "cmd /c del /F /Q /S @path" >nul
	ECHO [!timestampj!] - Cleaning Up Old Network Backup Files  in "%NetBakDir%\" ..... [INFO] >> %LogFile%
)
REM ######Backup Network Settings ###############


REM ######Backup Registry ###############
IF %BackUpReg% == 1 (
	IF NOT EXIST %NetRegBakDir% ( 
		for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampk=%timestampk%%%i )
		MKDIR %NetRegBakDir%
		IF %errorlevel% == 0 (
			ECHO [!timestampk!] - Creating Directory %NetRegBakDir% ..... [DONE] >> %LogFile%
		) else (
			ECHO [!timestampk!] - Creating Directory %NetRegBakDir% ..... [FAILED] >> %LogFile%
		)
	)

	IF EXIST %NetRegBakDir% (
		for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampl=%timestampl%%%i )
		regedit.exe /e "%NetRegBakDir%\WindowsRegistryBackup_!timestampl!.reg"
		IF %errorlevel% == 0 (
			ECHO [!timestampl!] - Backing Up Registry to "%NetRegBakDir%\WindowsRegistryBackup_!timestampl!.reg" ..... [DONE] >> %LogFile%
			icacls.exe "%NetRegBakDir%\*.reg"  /T /grant administrators:f  >nul
		) else (
			IF EXIST "%NetRegBakDir%\WindowsRegistryBackup_!timestampl!.reg" (
				ECHO [!timestampl!] - Backing Up Registry to "%NetRegBakDir%\WindowsRegistryBackup_!timestampl!.reg" ..... [VERIFY] >> %LogFile%
				icacls.exe "%NetRegBakDir%\*.reg"  /T /grant administrators:f  >nul
			) else (
				ECHO [!timestampl!] - Backing Up Registry to "%NetRegBakDir%\WindowsRegistryBackup_!timestampl!.reg" ..... [FAILED] >> %LogFile%
			)	
		)
	)
	  
	for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampm=%timestampm%%%i )
	FORFILES /D %DBMaxDays% /P "%NetRegBakDir%" /M *.reg /C "cmd /c del /F /Q /S @path" >nul
	ECHO [!timestampm!] - Cleaning Up Old Registry Backup Files  in "%NetRegBakDir%\" ..... [INFO] >> %LogFile%
)
REM ######Backup Registry ###############

 

REM ######Backup AD IFM ###############
IF %BackUpAD% == 1 (
	IF NOT EXIST %NetIFMBakDir% ( 
		for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampn=%timestampn%%%i )
		MKDIR %NetIFMBakDir%
		IF %errorlevel% == 0 (
			ECHO [!timestampn!] - Creating Directory %NetIFMBakDir% ..... [DONE] >> %LogFile%
		) else (
			IF EXIST %NetIFMBakDir% (
				ECHO [!timestampn!] - Creating Directory %NetIFMBakDir% ..... [DONE] >> %LogFile%
			) else (
				ECHO [!timestampn!] - Creating Directory %NetIFMBakDir% ..... [FAILED] >> %LogFile%
			)
		)
	)

	IF EXIST "%NetIFMBakDir%\current" (
		for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampo=%timestampo%%%i )
		REM takeown.exe /f "%NetIFMBakDir%\current"  /R /A  >nul
		icacls.exe "%NetIFMBakDir%\current\*.*"  /T /grant administrators:f  >nul
		IF EXIST "%NetIFMBakDir%\old" (
			REM takeown.exe /f "%NetIFMBakDir%\old"  /R /A  
			icacls.exe "%NetIFMBakDir%\old\*.*"  /T /grant administrators:f  >nul
			ECHO [!timestampo!] - Resetting IFM Directory Permissions  "%NetIFMBakDir%\old" ..... [INFO] >> %LogFile%
			RMDIR "%NetIFMBakDir%\old" /S /Q  > nul  
			ECHO [!timestampo!] - Deleting Previous FM Backup  "%NetIFMBakDir%\old" ..... [INFO] >> %LogFile%
		)
		MOVE  "%NetIFMBakDir%\current"  "%NetIFMBakDir%\old"  >nul
		MKDIR "%NetIFMBakDir%\current"   > nul
		for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampp=%timestampp%%%i )
		ECHO [!timestampp!] - Moving Last IFM Backup  "%NetIFMBakDir%\current" to "%NetIFMBakDir%\old" ..... [INFO] >> %LogFile%
	) else (
		MKDIR "%NetIFMBakDir%\current"   > nul
		for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampq=%timestampq%%%i )
		ECHO [!timestampq!] - Moving Last IFM Backup  "%NetIFMBakDir%\current" to "%NetIFMBakDir%\old" ..... [INFO] >> %LogFile%
	)

	IF EXIST "%NetIFMBakDir%\current" (
		for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampr=%timestampr%%%i )
		ntdsutil "activate instance ntds" ifm "create sysvol full %NetIFMBakDir%\current" quit quit > nul
		IF %errorlevel% == 0 (
			ECHO [!timestampr!] - Backing Up AD IFM to "%NetIFMBakDir%\current" ..... [DONE] >> %LogFile%
		) else (
			ECHO [!timestampr!] - Backing Up AD IFM to "%NetIFMBakDir%\current" ..... [VERIFY] >> %LogFile%
		)
	)
)
REM ######Backup AD IFM ###############




REM ########### SYNC FOLDERS###############################
IF %SyncFiles% == 1 (
	IF NOT EXIST %NetBakDataDir% ( 
		for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestamps=%timestamps%%%i )
		MKDIR %NetBakDataDir%
		IF %errorlevel% == 0 (
			ECHO [!timestamps!] - Creating Directory %NetBakDataDir% ..... [DONE] >> %LogFile%
		) else (
			IF EXIST %NetBakDataDir% (
				ECHO [!timestamps!] - Creating Directory %NetBakDataDir% ..... [DONE] >> %LogFile%
			) else (
				ECHO [!timestamps!] - Creating Directory %NetBakDataDir% ..... [FAILED] >> %LogFile%
			)
		)
	)

	IF EXIST %PathsToSync% ( 
		FOR /F "tokens=*" %%I IN (%PathsToSync%) DO (
			powershell.exe -Command "Copy-Item '%%I'   '%NetBakDataDir%\' -Recurse -Force "  > nul
			IF %errorlevel% == 0 (
				for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampt=%timestampt%%%i )
				ECHO [!timestampt!] - Synching : %%I to "%NetBakDataDir%\" ..... [DONE] >> %LogFile%
			) else (
				for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampu=%timestampu%%%i )
				ECHO [!timestampu!] - Synching : %%I to "%NetBakDataDir%\" ..... [VERIFY] >> %LogFile%
			)
		)
  )
)
REM ########### SYNC FOLDERS###############################


REM ############################Unmount SMB DRIVE###############################
NET USE %SMBMountDrive%  /delete  > nul
IF %errorlevel% == 0 (
	for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampv=%timestampv%%%i )
	ECHO [!timestampv!] - Unmounting : %SMBMountDrive% from %SMBShare% ..... [DONE] >> %LogFile%
) else (
	for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampw=%timestampw%%%i )
	ECHO [!timestampw!] - Unmounting : %SMBMountDrive% from %SMBShare% ..... [FAILED] >> %LogFile%
)
REM #############################################################################

for /f "tokens=*" %%i in  ('C:\JBACKUP\usr\bin\date.exe  "+%%H_%%M_%%s-%%d-%%B-%%Y"') do ( SET timestampy=%timestampy%%%i )
ECHO [!timestampy!] ----------------------------------------------------------------------- >> %LogFile%
