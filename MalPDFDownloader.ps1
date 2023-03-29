# Simple PS to find out how many mal PDFs are out there.
# Set the $firstPDF string to the URL of the MalPDF
# AKS 20230328

#TODO: 
#Create loop to search google for more PDFs in the directory
#############################################

############################################

get-date -Format o
#Zero out the text files that are used... should've saved them before running...
$files="malURLs.txt", "malDomains.txt", "malPDFURLs.txt", "malPDFDomains.txt", "temp.txt", "links.txt"
foreach ($file in $files){
    echo $null > "c:\users\admin\Documents\$file"
}

#Set the initial Mal PDF to crawl from.
$firstPDF="https://stellabakingcompany.com/wp-content/plugins/formcraft/file-upload/server/content/files/161409006c15e8---sonimenuwosuzulisujusaza.pdf"

#add $firstPDF to the temp.txt for the first PDF to check.
$firstPDF>"c:\users\admin\Documents\temp.txt"

#Add $firstPDF to the MalPDF list because we want to include it in the count.
$firstPDF>"c:\users\admin\Documents\malPDFURLs.txt"

#Start the Do while loop
$lineCount=Get-Content "c:\users\admin\Documents\temp.txt" | Measure-Object -line | Select-Object -ExpandProperty Lines
echo "lineCount = $lineCount"
DO
{
    $tempLine = Get-Content "c:\users\admin\Documents\temp.txt" -Tail 1
    $malPDF=$tempLine -split "/"
    $malPDFFilename=$malPDF[-1]
    $malPDFDomain=$malPDF[2]

    echo "Downloading $malPDFFilename from $malPDFDomain"
    Invoke-WebRequest -Uri $tempLine -OutFile "c:\users\admin\Documents\temp_mal_pdf.pdf" -UseBasicParsing
    echo "$malPDFFilename downloaded as temp_mal_pdf.pdf"
    #changed link from dynamic to static...
    $malPDFMalLinks=Get-Content c:\users\admin\Documents\temp_mal_pdf.pdf | select-string "/URI \(http"
    #$malPDFMalLinks
    echo ""
    foreach ($malPDFMalLink in $malPDFMalLinks){
        #Clean off the "/URI (" from the left and the ")" from the right.
        $tempstr=$malPDFMalLink.ToString().TrimEnd(")").TrimStart("/URI (")
        $tempstr
        #Create temp array to extract the domain later
        $tempDomain=$tempstr -split "/"
        #Check if it's the other Mal PDF links, or if it's the malicious link in the Mal PDF.
        if ($tempstr -notmatch '\.pdf$'){
            #It is the Mal links; save the URL and domain to the mal text files.
            #Check if the URL already exists, save it only if it doesn't already exist.
            $SEL=Select-String -Path "c:\users\admin\Documents\malURLs.txt" -Pattern $tempstr
            if ($SEL -eq $null){
                $tempstr>>"c:\users\admin\Documents\malURLs.txt"
            }
            #Check if the Domain already exists, save it only if it doesn't already exist.
            $SEL=Select-String -Path "c:\users\admin\Documents\malDomains.txt" -Pattern $tempDomain[2]
            if ($SEL -eq $null){
                $tempDomain[2]>>"c:\users\admin\Documents\malDomains.txt"
            }
        }elseif ($tempstr -match '\.pdf$'){
            #It is the Mal PDF links; save the URL and domain to the mal PDF text files.
            #Check if the URL already exists, save it only if it doesn't already exist.
            $SEL=Select-String -Path "c:\users\admin\Documents\malPDFURLs.txt" -Pattern $tempstr
            if ($SEL -eq $null){
                $tempstr>>"c:\users\admin\Documents\malPDFURLs.txt"
                #Also add it to the list of PDFs to check.
                $tempstr>>"c:\users\admin\Documents\temp.txt"
                echo "Added $tempstr to malPDFURLs"
            }
            #Check if the Domain already exists, save it only if it doesn't already exist.
            $SEL=Select-String -Path "c:\users\admin\Documents\malPDFDomains.txt" -Pattern $tempDomain[2]
            if ($SEL -eq $null){
                $tempDomain[2]>>"c:\users\admin\Documents\malPDFDomains.txt"
            }
        }
    
    }
    #Start block of code to check Google dork for additional Mal PDFs in the directory.
    $tempurl=$tempstr -split "/"
    $directory=$tempstr.TrimEnd($tempurl[-1])

    $first="https://www.google.com/search?q=inurl:%22$directory%22+filetype:pdf"
    $html=Invoke-WebRequest -Uri $first -UseBasicParsing
    foreach ($link in $html.Links.href){
        $link>>"c:\users\admin\Documents\links.txt"
    }
    $templistoflinks=Get-Content "C:\users\admin\Documents\links.txt" | select-string $directory | select-string "\.pdf"
    foreach ($templink in $templistoflinks){
        $tempglink=$templink -split "="
        $tempglink2=$tempglink[1]
        $tempglink=$tempglink2 -split "&"
        $tempstr=$tempglink[0].trimend(",")
        echo "Found another one from Google: $tempstr"
        #Check if the URL already exists, save it only if it doesn't already exist.
        $SEL=Select-String -Path "c:\users\admin\Documents\malPDFURLs.txt" -Pattern $tempstr
        if ($SEL -eq $null){
            $tempstr>>"c:\users\admin\Documents\malPDFURLs.txt"
            #Also add it to the list of PDFs to check.
            $tempstr>>"c:\users\admin\Documents\temp.txt"
            echo "Added $tempstr to malPDFURLs"
        }
    }
    echo $null >"c:\users\admin\Documents\links.txt"
    #End block of code to check Google dork for additional Mal PDFs in the directory.

    get-date -Format o

    #Clean up the temp.txt; filter out the $tempLine that was just checked; overwrite the temp.txt file without $tempLine; update
    #the $lineCount
    $tempList = Get-Content "c:\users\admin\Documents\temp.txt" | Select-String -pattern $tempLine -NotMatch 
    $tempList > "c:\users\admin\Documents\temp.txt"
    $lineCount=Get-Content "c:\users\admin\Documents\temp.txt" | Measure-Object -line | Select-Object -ExpandProperty Lines
    echo "lineCount = $lineCount"

#End Do while loop
} While ($lineCount -gt 0)



