#Requires -RunAsAdministrator
#Requires -Module Pester
# Test-BlockOutgoing.ps1
#
# Unit tests for Block-Outgoing.ps1 using Pester framework.

# Load the function into the test session
. "$PSScriptRoot\Block-Outgoing.ps1"

Describe "Block-Outgoing Function Tests" {

    Context "Valid file paths" {
        It "Should create a firewall rule for an executable file" {
            Mock New-NetFirewallRule { $true } -Verifiable

            Block-Outgoing -Path "C:\Test\App.exe"

            Assert-MockCalled New-NetFirewallRule -Exactly 1
        }
    }

    Context "Valid directory paths" {
        It "Should block all executables in a directory" {
            Mock fd { "C:\Test\One.exe", "C:\Test\Two.exe" } -Verifiable
            Mock New-NetFirewallRule { $true } -Verifiable

            Block-Outgoing -Path "C:\Test"

            Assert-MockCalled New-NetFirewallRule -Exactly 2
        }
    }

    Context "Invalid paths" {
        It "Should show a warning for invalid path" {
            Mock Write-Warning { $true } -Verifiable

            Block-Outgoing -Path "C:\DoesNotExist"

            Assert-MockCalled Write-Warning -Exactly 1
        }
    }

    Context "Error handling" {
        It "Should catch errors and write an error message" {
            Mock New-NetFirewallRule { throw "Firewall rule creation failed" } -Verifiable
            Mock Write-Error { $true } -Verifiable

            Block-Outgoing -Path "C:\Test\App.exe"

            Assert-MockCalled Write-Error -Exactly 1
        }
    }
}
