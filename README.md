# Translation Utils
 
Export translations from Alma into Excel file per language.

Import the Excel files, merge into the 2 big UIL files, and commit them to SVN.

Compare Excel file to the UIL to verify the labels were merged.

### TODO:

# Import:
Generate UIL files
Save old UIL files with timestamp
Commit - From which dir?
svn commit --username "orim" --password "..." -m "JIRA: URM-24347 Developer: orim Description: test" code_tables_data_customer1.xml

# Export:
From DB? support all filters - perhaps with configuration to allow running just once
According to mapping_table_TranslationData.xml (from the Release branch)
Allow exporting only delta
