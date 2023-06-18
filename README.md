# Translation Utils
 
Export translations from Alma into Excel file per language.

Import the Excel files, merge into the 2 big UIL files, and commit them to SVN.

Compare Excel file to the UIL to verify the labels were merged.

Export config:

Lang-code - patron-facing/all, product (ALMA / RESEARCH / SUPRIMA / LEGANTO) and/or area (UNIMARC / CNMARC / KORMARC / MARC21 / GND / DC), all/ Delta (only lines without translation, supposedly new)

AR - pf,ALMA,all

HE - all,ALMA,Delta

FR - all,ALMA+UNIMARC,Delta

FR - all,LEGANTO,Delta

# Installation

Download code from here (https://github.com/ori229/Translation-Utils/archive/refs/heads/master.zip)

Unzip to a folder under C:\

Install Oracle 12 Client as explained here
https://docs.bentley.com/LiveContent/web/Bentley%20i-model%20Composition%20Service%20for%20S3D%20Help-v2/en/GUID-AEFD08A2-1EEF-404E-93F9-C069FA46F33C.html
or take Oracle.ManagedDataAccess.dll from the zip you have downloaded, and update private.properties with the path accordinaly.

Verify you are connected to the VPN

Open PowerShell as administrator and run: (for any questions answer Yes to all)

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine    


"cd" to Translation-Utils folder in PowerShell and run:

Unblock-File *.ps1

Unblock-File utils\\*.ps1


Right-click on the Export-Excel file and choose "Run with PowerShell"
