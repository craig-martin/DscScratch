
@{
	RootModule = "FimPowerShellModule.psm1"

    NestedModules     = "ConvertFimExportToPSObject.ps1",
                        "GetFimObjectByXPath.ps1",
                        "GetFimObjectID.ps1",
                        "GetFimRequestParameter.ps1",
                        "GetFimSet.ps1",
                        "GetObjectSid.ps1",
                        "NewFimEmailTemplate.ps1",
                        "NewFimImportChange.ps1",
                        "NewFimImportObject.ps1",
                        "NewFimManagementPolicyRule.ps1",
                        "NewFimNavigationBarLink.ps1",
                        "NewFimSchemaAttribute.ps1",
                        "NewFimSchemaBinding.ps1",
                        "NewFimSchemaObjectType.ps1",
                        "NewFimSearchScope.ps1",
                        "NewFimSet.ps1",
                        "NewFimSynchronizationRule.ps1",
                        "NewFimWorkflowDefinition.ps1",
                        "RemoveFimSet.ps1",
                        "SetFimManagementPolicyRule.ps1",
                        "SetFimSet.ps1",
                        "SetFimWorkflowDefinition.ps1",
                        "SkipDuplicateCreateRequest.ps1",
                        "StartSQLAgentJob.ps1",
                        "SubmitFimRequest.ps1",
                        "WaitFimRequest.ps1"

# Functions to export from this module
FunctionsToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

    GUID              = "{fd710a00-a22d-43c9-a2bd-183fb07ab4ea}"

    Author            = "Craig Martin, Brian Desmond, James Booth"

    ModuleVersion     = "1.0.1.0"

    PowerShellVersion = "3.0"

    CLRVersion        = "4.0"

}