﻿@{

# Version number of this module.
ModuleVersion = '1.0'

# ID used to uniquely identify this module
GUID = 'e19efa8b-5339-4039-a9ee-a183bc5ae3df'

# Author of this module
Author = 'Craig Martin'

# Company or vendor of this module
CompanyName = 'PowerShell.org'

# Copyright statement for this module
Copyright = '(c) 2013 PowerShell.org. All rights reserved.'

# Description of the functionality provided by this module
Description = 'This Module is used to support the execution of query, install & uninstall functionalities on local FIM Service Set items through Get, Set and Test API on the DSC managed nodes.'

# Functions to export from this module
FunctionsToExport = '*'

# HelpInfo URI of this module

# HelpInfoURI = ''

NestedModules     = "cFimManagementPolicyRule.psm1","cFimService_ManagementPolicyRule.psm1"

# Modules that must be imported into the global environment prior to importing this module
#RequiredModules = @("FimPowerShellModule")

}