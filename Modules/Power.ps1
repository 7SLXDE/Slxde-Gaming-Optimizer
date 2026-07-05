function Get-PowerPlan {

    try {

        $Output = powercfg /getactivescheme

        if ($Output -match '\((.+)\)') {
            return $Matches[1]
        }

        return "Unknown"

    }
    catch {

        return "Unknown"

    }

}