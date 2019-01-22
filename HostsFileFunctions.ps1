<#
.SYNOPSIS
	Returns the entries in a hosts file
.DESCRIPTION
	Get-HostsFileEntry returns the list of entries from a remote or local hosts file
.PARAMETER ComputerName
    The name of the computer te query. If left blank, it defaults to the local computer.
.EXAMPLE
	Get-HostsFileEntry A0001990

    Returns the hosts file content. If the hosts file has no values, then it returns nothing.
.INPUTS
    A computer name
.OUTPUTS
    A custom PSObject with properties:

    [string]HostName - the hostname of the entry
    [ipaddress]IPAddress - the IP address of the entry
.NOTES
	Author: Anthony Howell
.LINK
	
#>
Function Get-HostsFileEntry
{
    Param
    (
        [Parameter(Mandatory=$false)]
        [string]$ComputerName = $env:COMPUTERNAME
    )
    Begin
    {
        $return = @()
    }
    Process
    {
        If($ComputerName -ne $env:COMPUTERNAME)
        {
            If(!(Test-Connection $ComputerName))
            {
                Throw "Unable to contact $ComputerName"
            }
            Else
            {
                $content = Get-Content \\$ComputerName\c`$\Windows\System32\drivers\etc\hosts | ?{$_ -notlike "#*"}
            }
        }
        Else
        {
            $content = Get-Content C:\Windows\System32\drivers\etc\hosts | ?{$_ -notlike "#*"}
        }
        ForEach($line in $content)
        {
            If($line -match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}")
            {
                $return += New-Object PSObject -property @{
                    "IPAddress" = $Matches[0]
                    "HostName" = ($line | Select-String "\s\S*($|\s|\n)").Matches[0].Value.Trim()
                }
                #($line | Select-String "\s\S*($|\s|\n)").Matches#[0]#.Value.Trim()
            }
        }
    }
    End
    {
        Return $return
    }
}
<#
.SYNOPSIS
	Adds an entry to a hosts file
.DESCRIPTION
	Add-HostsFileEntry adds an entry to a remote or local hosts file
.PARAMETER Computername
    The name of the computer to edit the hosts file on. If left blank, it defaults to the local computer.
.PARAMETER IPAddress
    The
.EXAMPLE
	
.EXAMPLE
    
.INPUTS

.OUTPUTS
    
.NOTES
	Author: Anthony Howell
.LINK
	
#>
Function Add-HostsFileEntry
{
    Param
    (
        [Parameter(Mandatory=$false)]
        [string]$Computername = $env:COMPUTERNAME
        ,
        [Parameter(Mandatory=$true,Position=1)]
        [ipaddress]$IPAddress
        ,
        [Parameter(Mandatory=$true,Position=2)]
        [string]$HostName
    )
    Begin
    {
        
    }
    Process
    {
        If($ComputerName -ne $env:COMPUTERNAME)
        {
            If(!(Test-Connection $ComputerName))
            {
                Throw "Unable to contact $ComputerName"
            }
            Else
            {
                "`n$($IPAddress.IPAddressToString)`t$HostName" | Out-File -Encoding ascii -Append \\$ComputerName\c`$\Windows\System32\drivers\etc\hosts
            }
        }
        Else
        {
            "`n$($IPAddress.IPAddressToString)`t$HostName" | Out-File -Encoding ascii -Append C:\Windows\System32\drivers\etc\hosts
        }
    }
    End
    {

    }
}
<#
.SYNOPSIS
	
.DESCRIPTION
	
.PARAMETER UserName
    
.EXAMPLE
	
.EXAMPLE
    
.INPUTS

.OUTPUTS
    
.NOTES
	Author: Anthony Howell
.LINK
	
#>
Function Remove-HostsFileEntry
{
    Param
    (
        [Parameter(Mandatory=$false,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$Computername = $env:COMPUTERNAME
        ,
        [Parameter(Mandatory=$true,Position=1)]
        [ipaddress]$IPAddress
    )
    Begin
    {

    }
    Process
    {
        If($ComputerName -ne $env:COMPUTERNAME)
        {
            If(!(Test-Connection $ComputerName))
            {
                Throw "Unable to contact $ComputerName"
            }
            Else
            {
                Get-Content \\$ComputerName\c`$\Windows\System32\drivers\etc\hosts | %{If($_ -notlike "$($IPAddress.IPAddressToString)*"){$_}} | Out-File -Encoding ascii \\$Computername\c`$\Windows\System32\drivers\etc\hosts
            }
        }
        Else
        {
            Get-Content C:\Windows\System32\drivers\etc\hosts | %{If($_ -notlike "$($IPAddress.IPAddressToString)*"){$_}} | Out-File -Encoding ascii C:\Windows\System32\drivers\etc\hosts
        }
    }
    End
    {

    }
}

<#
# Copyright (c) 1993-2009 Microsoft Corp.
#
# This is a sample HOSTS file used by Microsoft TCP/IP for Windows.
#
# This file contains the mappings of IP addresses to host names. Each
# entry should be kept on an individual line. The IP address should
# be placed in the first column followed by the corresponding host name.
# The IP address and the host name should be separated by at least one
# space.
#
# Additionally, comments (such as these) may be inserted on individual
# lines or following the machine name denoted by a '#' symbol.
#
# For example:
#
#      102.54.94.97     rhino.acme.com          # source server
#       38.25.63.10     x.acme.com              # x client host

# localhost name resolution is handled within DNS itself.
#       127.0.0.1       localhost
#       ::1             localhost

10.0.7.101      a0003604#>