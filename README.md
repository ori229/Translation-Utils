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

Export is done from Oracle, so:
Install Oracle 12 Client as explained here
https://docs.bentley.com/LiveContent/web/Bentley%20i-model%20Composition%20Service%20for%20S3D%20Help-v2/en/GUID-AEFD08A2-1EEF-404E-93F9-C069FA46F33C.html
Files are in: Y:\Development\v1.0\AlmaEX\Ori\scripts\Translation-Utils\winx64_12102_client
or simply take Oracle.ManagedDataAccess.dll and update private.properties 
