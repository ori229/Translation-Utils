Set-StrictMode -Version Latest

Import-Module $PSScriptRoot\utils\Utils-Excel.ps1    -Force
Import-Module $PSScriptRoot\utils\Utils-General.ps1  -Force
Import-Module $PSScriptRoot\utils\Utils-UilFiles.ps1 -Force

######################################
function main() {
    $pathRoot = $PSScriptRoot+"\work\"
    $now = Get-Date -format "yyyy-MM-dd_HH-mm-ss"

    $logFile = $pathRoot+$now+".log.txt"
    log "Starting export. Folder: $pathRoot"

    $tableCodeToText_DB = new-object System.Collections.Hashtable
    $tableAndCodeToInfo_Excel  = new-object System.Collections.Hashtable
    $tableCodeAndLangToText_Excel = new-object System.Collections.Hashtable
    $tableCodeAndLangToText_Uil   = new-object System.Collections.Hashtable # case sensitive

    $DEL = " _I_ "
    
    # Read UilFiles from the Release Branch:
    $releaseBranchUrl = (getSvnBranchesUrls)[1]
    fetchUilFilesFromSvn $releaseBranchUrl
    readUilFiles

    # Read from the DB (because we might have new labels which are not yet in code_table_translation.uil):
    readEnFromDB

    # Create Excel file. English from the DB, and translation (if exists) from the UIL file:
    exportExcelFiles

    log "Done!"
    #echo "Press any key to close"
    #cmd /c pause | out-null
}

######################################
function exportExcelFiles() {
    exportExcelFile("HE")
}

######################################
function exportExcelFile($lang) {
    $langHeader = 'Translation ('+ $lang +')'
    $results = @()
    foreach ($h in $tableCodeToText_DB.GetEnumerator()) {
        $key = $($h.Name)
        $en = $tableCodeToText_DB[$key]
        if ($en -match ".*[a-zA-Z].*") {
            #log "good - has letters - $en"
        } else {
            #log "skip because the desc for en has no English letters: $en"
            continue
        }
        if ($en.contains("_") -and -not $en.contains(" ")) {
            #log "skip because the desc for en seem like a code: $en"
            continue;
        }

        $keyWithLang = $key+$DEL+$lang
        $translation=""
        if ($tableCodeAndLangToText_Uil.containsKey($keyWithLang)) {
            $translation = $tableCodeAndLangToText_Uil[$keyWithLang]
            #log "Found! $translation"
        }

        $details = @{            
                'Code table' = $key -replace "$DEL.*",""
                'codeValue'  = $key -replace ".*$DEL",""
                'Sub system' = "."
                'Original text (EN)' = $en
                $langHeader = $translation
        }                           

        $results += New-Object PSObject -Property $details  
    }
    $results |
    Select-Object "Code table", "codeValue", "Sub system", "Original text (EN)", $langHeader | 
            Sort-Object -Property @{Expression="Code table"; Descending=$false}, @{Expression="codeValue" ;Descending=$false} |
            Export-Csv $pathRoot$lang".translations.csv" -NoTypeInformation -Encoding UTF8
    #TODO enable save-as XLSX
}

######################################
function readEnFromDB() {
    add-type -path (getOracleClientDllPath)

    try{
        $con = New-Object Oracle.ManagedDataAccess.Client.OracleConnection -ArgumentList (getOracleConnectionString)
        $con.Open()
        #Write-Host ("Connected to database: {0} – running on host: {1} – Servicename: {2} – Serverversion: {3}" -f $con.DatabaseName, $con.HostName, $con.ServiceName, $con.ServerVersion) -ForegroundColor Cyan -BackgroundColor Black
        $sql="select CODE_TABLE_NAME,CODE,DESCRIPTION from C_C_CODE_TABLES where INSTITUTIONID=11 and lang='en'"
        $sql=@"
        select CODE_TABLE_NAME,CODE,DESCRIPTION from C_C_CODE_TABLES where INSTITUTIONID=11 and lang='en' and CODE_TABLE_NAME
in (		'MashUpLabels',		'AlmaViewerLabels',		'DueDateUOM',		'dcTypeToDiscoveryType',		'FixedValueNone',
		'HFulPolicy.DueDateFixedValues',		'PhysicalMaterialType',		'MashUpServicesTypes',
		'MashUpGroups',		'UserBlockDescription',		'HFrUserFinesFees.fineFeeType',		'HFrUserFinesFees.fineFeeStatus',
		'Currency_CT',		'SIP2_Language',		'SIP2ExtensionTypes',		'SIP2ItemIdentifier',
		'FineFeePaymentReceiptLetter',		'FineFeeStatusReason',		'FineFeeTransactionType',		'FineFeeTransactionReason',
		'FineIntervalsForLetter',		'PaymentMethod',		'SIPPaymentMethod',		'WorkbenchPaymentMethod',
		'FulBorrowingInfoLetter',		'BibliographicMaterialType',		'AssignedObjectName',		'FulLostLoanLetter',
		'SmsFulLostLoanLetter',		'FulLostLoanNotificationLetter',		'SmsFulLostLoanNotificationLetter',		'FulOverdueAndLostLoanLetter',
		'SmsFulOverdueAndLostLoanLetter',		'FulOverdueAndLostLoanNotificationLetter',		'SmsFulOverdueAndLostLoanNotificationLetter',		'FulLostRefundFeeLoanLetter',
		'FulUserLoansCourtesyLetter',		'SmsFulUserLoansCourtesyLetter',		'FulBorrowedByLetter',		'FulShortLoanLetter',
		'FulShortenedDueDateLetter',		'SmsFulShortenedDueDateLetter',		'FulOutgoingEmailLetter',		'FulCancelEmailLetter',
		'FulRenewEmailLetter',		'FulCancelRequestLetter',		'WorkOrderCancellationReasons',		'SmsFulCancelRequestLetter',
		'RequestCancellationReasons',		'FulCitationsSlipLetter',		'FulPlaceOnHoldShelfLetter',		'SmsFulPlaceOnHoldShelfLetter',
		'FulUserBorrowingActivityLetter',		'SmsFulUserBorrowingActivityLetter',		'FulUserOverdueNoticeLetter',		'SmsFulUserOverdueNoticeLetter',
		'FulItemChangeDueDateLetter',		'SmsFulItemChangeDueDateLetter',		'FulDigitizationNotificationItemLetter',		'FulDigitizationDocumentDeliveryNotificationLetter',
		'DigitizationType',		'InterestedInLetter',		'PhysicalDescription',		'holdingCallNumberType',
		'PROCESSTYPE',		'resourceType',		'FulfillmentPlanStepTypes',		'FulfillmentPlanStatuses',
		'RequestDestinationTypes',		'ApprovalStatus',		'RequestRejectReason',		'ResourceRequestStatuses',
		'BorrowingRSRequestStatuses',		'LendingRSRequestStatuses',		'RequestStepStatus',		'ResourceRequestStatusNotes',
		'RequestPriorities',		'RequestPrioritiesExternal',		'PlanStatuses',		'ExpiredHoldShelfItemsStatus',
		'OutgoingResourceRequestStatuses',		'YesNo',		'mailReason.xsl',		'footer.xsl',
		'FulRequestMoveItemTypes',		'CountryCodes',		'UserAddressTypes',		'UserEmailTypes',
		'UserPhoneTypes',		'FinesAndFeesReportLetter',		'HItemLoan.processStatus',		'ItemPolicy',
		'FulPersonalDeliveryLetter',		'LendingReqReportSlipLetter',		'FulReturnReceiptLetter',		'FulLoanReceiptLetter',
		'PINNumberGenerationLetter',		'UserDeletionLetter',		'ExportUserLetter',		'WorkbenchPreferencesDescription',
		'BasicRequestedMedia',		'AdditionalRequestedMedia',		'DeliveryMetadataFieldsDisplay',		'DCProfileQualifiedDublinCore',
		'DCProfileDCApplicationprofile1',		'DCProfileDCApplicationprofile2',		'BorrowerOverdueEmailLetter',		'QueryToPatronLetter',
		'UserNotificationsLetter',		'ResendNotificationLetter',		'TrialLetter',		'ILLWillSupplyReason',
		'LendingRecallEmailLetter',		'FulfillmentPatronFacingDescriptors',		'ExternallyObtainedEmailLetter',		'LegantoNotificationsLetter',
		'LegantoUpcomingDueDatesNotificationsLetter',		'ReadingListCitationSecondaryTypes',		'RequestTaskNameStaffDisplay',		'RequestTaskNamePatronDisplay',
		'LibraryNoticesOptInDisplay',		'SocialLoginInviteLetter',		'SocialLoginAccountAttachedLetter',		'SocialLoginMessages',
		'LoginUsingOneTimeTokenLetter',		'EmailRecordsLetter',		'ResourceSharingReturnSlipLetter',		'ResourceSharingReceiveSlipLetter',
		'CloudIdPUserCreatedLetter',		'LinkedAccountSharedFiledsNames',		'UILegantoLabels',		'LegantoNotificationsLetter',
		'RequestFormTypes',		'MandatoryBorrowingWorkflowSteps',		'PQAccessModel ',		'PublicAccessModel',
		'MandatoryLendingWorkflowSteps',		'OptionalBorrowingWorkflowSteps',		'OptionalLendingWorkflowSteps',		'RequestFormats',
		'GeneralMessageEmailLetter',		'LenderWillSupplyEmailLetter',		'LenderCheckedInEmailLetter',		'LenderRejectEmailLetter',
		'LenderShipEmailLetter',		'LenderRenewResponseEmailLetter',		'BorrowerReceiveEmailLetter',		'BorrowerReturnEmailLetter',
		'ResourceSharingCopyrightsStatus',		'AdvancedSearchIndexFieldLabels',		'GetitServicelabels',		'SuggestionsLabels',
		'CitationTrail',		'LinksAndGeneralElectronicServicesLabels',		'LocalFieldsLabels',		'PrimaInterfaceLabels',
		'PrimaAdvancedMediaTypeLabelsForAlma',		'PrimaAdvancedLanguagesLabels',		'PrimaAdvancedMediaTypeLabels',		'PrimaAriaLabels',
		'PrimaCalculatedAvailabilityTextLabels',		'PrimaCitationLabels',		'PrimaDigitizationLabels',		'PrimaDisplayConstantsLabels',
		'PrimaEShelfTileLabels',		'PrimaErrorMessagesLabels',		'PrimaFacetFsizeValuesCodesLabels',		'PrimaFacetLabels',
		'PrimaFacetResourceTypeLabels',		'PrimaFacetsCodeFieldsLabels',		'PrimaFavoritesLabels',		'PrimaFinesListLabels',
		'PrimaFullDisplayLabels',		'PrimaGenreLabels',		'PrimaGetITTab1Labels',		'PrimaGetitTileLabels',
		'PrimaHeaderFooterTilesLabels',		'PrimaIconCodesLabels',		'PrimaInterfaceLanguageLabels',		'PrimaKeepingThisItemTileLabels',
		'PrimaLanguageCodesLabels',		'PrimaLibraryCardLabels',		'PrimaLoansListLabels',		'PrimaLocationsTabLabels',
		'PrimaMetadataFormatLabels',		'PrimaMyPreferencesTileLabels',		'PrimaPersonalSettingsLabels',		'PrimaPurchaseRequestLabels',
		'PrimaRequestLabels',		'PrimaRequestTabMessagesLabels',		'PrimaRequestoptionsLabels',		'PrimaRequestsListLabels',
		'PrimaResourceSharingLabels',		'PrimaResultsTileLabels',		'PrimaRisLabels',		'PrimaSearchProfileLabels',
		'PrimaSearchTileLabels',		'PrimaSendEmailLabels',		'PrimaSortValuesLabels',		'PrimaTagsTileLabels',
		'PrimaTopLevelFacetLabels',		'PrimaUserLoginLabels',		'AlmaUserLoginLabels',		'PrimaUserSpaceMenuLabels',
		'PrimaUserTileLabels',		'PrimaViewItLabels',		'PrimaViewLabels',		'PrimaEndUserDepositLabels',
		'PrimaRepresentationViewerLabels',		'PrimaRelatedItemseLabels',		'DepositReturnReasons',		'DepositDeclineReasons',
		'ILLFulNetworkRejectReasons',		'DepositActivityLetter',		'FulFinesFeesNotificationLetter',		'FulPickupRequestReportLetter',
		'FulRequestsReportLetter',		'DCProfileFieldsDescriptionViewer',		'NeedsPatronInformationOptions',		'DcType',
		'HoldingsDisplayLabelsAndOrder',		'InternalLoginMessages',		'ResetPwLetter',		'PurchaseRequestStatusLetter',
		'AutoLocateRejectReason',		'ILLUnfillReasons',		'AutoRenewRejectReasons',		'ViewerShareButtons',
		'DepositEnrichmentLabels',		'ILLiadExportTypes',		'HandleBorrowingRequestForPurchaseRequest',		'DepositStatusUpdateLetter',
		'PR_RejectReasons',		'BorrowerClaimEmailLetter',		'ChangeRapidoRequestTermsLetter',		'QueryToRequesterLetter',
		'ResearchAssetsAddedToProfileLetter',		'PurchaseRequestStatus',		'PickupRulesRequestTypes',		'PlanTypes',
		'PatronWelcomeLetter')
"@
        $adap = New-Object Oracle.ManagedDataAccess.Client.OracleDataAdapter($sql,$con)
        $oraCmdBldr = New-Object Oracle.ManagedDataAccess.Client.OracleCommandBuilder($adap)
    
        [System.Data.DataSet]$dataset = New-Object System.Data.DataSet
        $tempNum = $adap.Fill($dataset)
        Write-Host "Num of rows: $tempNum"
        #$dataset.Tables[0]

        for($i=0;$i -lt $dataset.Tables[0].Rows.Count;$i++)  { 
            #write-host "row num $i :    "
            $codeTableName = $($dataset.Tables[0].Rows[$i][0])
            $code          = $($dataset.Tables[0].Rows[$i][1])
            $translation   = $($dataset.Tables[0].Rows[$i][2])
            $hashKey = $codeTableName + $DEL + $code
            if ($tableCodeToText_DB.ContainsKey($hashKey)) {
                log " WARNING: Key already in hash: $hashKey "
            } else {
                $tableCodeToText_DB.add($hashKey, $translation)
                #log "...........added to hash:", $hashKey, $translation
            }
        }

        Remove-Variable dataset
    } catch {
        Write-Error ("Can't open connection: {0}`n{1}" -f `
            $con.ConnectionString, $_.Exception.ToString())
    } finally{
        if ($con.State -eq 'Open') { $con.close() }
    }
}

main