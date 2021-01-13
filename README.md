# Translation Utils
 
Export translations from Alma into Excel file per language.

Import the Excel files, merge into the 2 big UIL files, and commit them to SVN.

Compare Excel file to the UIL to verify the labels were merged.


Export is done from Oracle, so:
Install Oracle 12 Client as explained here
https://docs.bentley.com/LiveContent/web/Bentley%20i-model%20Composition%20Service%20for%20S3D%20Help-v2/en/GUID-AEFD08A2-1EEF-404E-93F9-C069FA46F33C.html
Files are in: Y:\Development\v1.0\AlmaEX\Ori\scripts\Translation-Utils\winx64_12102_client
Might need to run as admin.

### TODO:

# Import:
Generate UIL files
Save old UIL files with timestamp
Commit - From which dir? Consult with Yuri before doing for the first time.
svn commit --username "orim" --password "..." -m "JIRA: URM-24347 Developer: almatranslation Description: Merge new translations for: HE,FR" code_tables_data_customer1.xml

# Export:
According to mapping_table_TranslationData.xml (from the Release branch)

Allow exporting only delta (lines which don't have translations)

Support all filters - with configuration file to allow running just once:

AR - pf,Alma,all             --> AR_pf_Alma_all.csv
HE - all,Alma,Delta          --> HE_all_Alma_Delta.csv
FR - all,Alma+Unimarc,Delta  --> etc.
FR - all,Leganto,Delta

getPreviousBranchName()

Future:

Add sub-system:
select SUB_SYSTEM from C_C_TABLE_OF_TABLES
where CODE_TABLE_NAME='AdvancedSearchIndexFieldLabels' and INSTITUTIONID=11;

Fix the language name in the first line