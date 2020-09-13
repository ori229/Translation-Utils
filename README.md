# Translation Utils
 
Export translations from Alma into Excel file per language.

Import the Excel, merge into UIL files, and commit them to SVN.

Compare Excel file to the UIL to verify the labels were merged.

# TODO:
# Handle all 3 branches
# Generate UIL file
# Save old UIL file with timestamp

# commit - From which dir?  DESCRIPTION=JIRA: URM-24347 Developer: almatranslation Description: ...
# svn commit --username ${SVN_USER} --password ${SVN_PASS} -m "${DESCRIPTION} build id:${BUILD_ID} " ${WORKSPACE}/factory_settings/alma_labels.uil

# Export:
# From DB? support all filters - perhaps with configuration to allow running just once
