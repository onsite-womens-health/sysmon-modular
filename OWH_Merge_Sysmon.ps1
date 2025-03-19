# Get the current script directory (relative to where the script is located)
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

# Define the relative paths to the root and custom configuration directories
$rootConfigFile = Join-Path $scriptDirectory 'sysmonconfig.xml'
$customXmlFolder = Join-Path $scriptDirectory '0_custom_configuration'

# Print out the base XML file being used
Write-Host "Using base config file: $rootConfigFile"

# Get the list of all XML files from the custom folder
$xmlFiles = Get-ChildItem -Path $customXmlFolder -Filter "*.xml"

# Print out the files that will be merged for debugging
Write-Host "Files to merge:"
$xmlFiles | ForEach-Object { Write-Host $_.FullName }

# Load the root Sysmon config
$mergedXml = [xml](Get-Content -Path $rootConfigFile)

# Loop through each custom XML file to merge
foreach ($xmlFile in $xmlFiles) {
    Write-Host "Merging: $($xmlFile.FullName)"
    
    # Load custom XML
    $newXml = [xml](Get-Content -Path $xmlFile.FullName)
    
    # Check if the new XML has a SysmonConfig node and handle merging
    if ($newXml.Sysmon.EventFiltering) {
        Write-Host "Merging EventFiltering from $($xmlFile.FullName)"
        
        # Import and append each child node from the custom XML to the root XML
        $newXml.Sysmon.EventFiltering.ChildNodes | ForEach-Object {
            $importedNode = $mergedXml.ImportNode($_, $true)
            $mergedXml.Sysmon.EventFiltering.AppendChild($importedNode)
        }
    } else {
        Write-Warning "No EventFiltering node found in $($xmlFile.FullName)"
    }
}

# Save the merged XML into a new output file
$mergedXml.Save("OWH_sysmonconfig.xml")
Write-Host "Successfully merged XML files into OWH_sysmonconfig.xml"
