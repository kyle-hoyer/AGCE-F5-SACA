Get-AzMarketplaceTerms `
    -Publisher 'f5-networks' `
    -Product 'f5-big-ip-byol' `
    -Name 'f5-big-all-2slot-byol' `
    | `
Set-AzMarketplaceTerms -Accept