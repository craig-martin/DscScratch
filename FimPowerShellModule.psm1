$ProgressPreference = "SilentlyContinue"

###
### Load the FIMAutomation Snap-In
###
if ($Args -and $Args.Contains('NoSnapinCheck'))
{
    Write-Verbose "Skipping check for FIMAutomation snapin"
}
else
{
    if (-not (Get-PSSnapin | Where-Object { $_.Name -eq 'FIMAutomation' }))
    {
        Write-Verbose "Loading snapin"
        try
        {
            Add-PSSnapin FIMAutomation -ErrorAction SilentlyContinue -ErrorVariable err
        }
        catch
        {
        }

        if ($err)
        {
            if ($err[0].ToString() -imatch "has already been added")
            {
                Write-Verbose "FIMAutomation snap-in has already been loaded."
            }
            else
            {
                Write-Error "FIMAutomation snap-in could not be loaded." -ErrorAction Stop
            }
        }
        else
        {
            Write-Verbose "FIMAutomation snap-in loaded successfully."
        }
    }
    else
    {
        Write-Verbose "FimAutomation snap-in already loaded."
    }
}

# backwards compat for the old names of these functions
New-Alias -Name Add-FimSchemaBinding -Value New-FimSchemaBinding
New-Alias -Name Add-FimSchemaAttribute -Value New-FimSchemaAttribute
New-Alias -Name Add-FimSchemaObject -Value New-FimSchemaObjectType
New-Alias -Name Add-FimSet -Value New-FimSet

# this is required because aliases aren't
# exported by default
Export-ModuleMember -Function * -Alias *