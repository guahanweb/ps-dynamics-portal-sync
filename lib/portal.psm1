Add-Type -AssemblyName System.Net.Http;

function Get-PortalData {
  Param(
    [Parameter(Mandatory=$True)]
    [String]
    $Path,
    [Parameter(Mandatory=$True)]
    $CrmClient
  )

  # Prepare oDataHeaders
  $oDataHeaders = New-Object 'system.collections.generic.dictionary[string,system.collections.generic.list[string]]';
  [Collections.Generic.List[String]]$oDataPrefer = 'odata.include-annotations="OData.Community.Display.V1.FormattedValue"';
  $oDataHeaders['Prefer'] = $oDataPrefer;

  $response = [System.Net.Http.HttpResponseMessage]$CrmClient.ExecuteCrmWebRequest(
    [System.Net.Http.HttpMethod]::Get,
    $Path,
    '',
    $oDataHeaders,
    'application/json'
  );

  $task = $response.Content.ReadAsStringAsync();
  $success = $task.Wait(15000);
  if (!$success) {
    Write-Output $response
  }

  ($($task.Result) | ConvertFrom-Json).value;
}

function Update-PortalData {
  Param(
    [Parameter(Mandatory=$True)]
    [String]
    $Path,
    [Parameter(Mandatory=$True)]
    [String]
    $Payload,
    [Parameter(Mandatory=$True)]
    $CrmClient
  );

  # Prepare oDataHeaders
  $oDataHeaders = New-Object 'system.collections.generic.dictionary[string,system.collections.generic.list[string]]';
  [Collections.Generic.List[String]]$oDataPrefer = 'odata.include-annotations="OData.Community.Display.V1.FormattedValue"';
  $oDataHeaders['Prefer'] = $oDataPrefer;

  $response = [System.Net.Http.HttpResponseMessage]$CrmClient.ExecuteCrmWebRequest(
    "PATCH",
    $Path,
    $Payload,
    $oDataHeaders,
    'application/json'
  );

  $task = $response.Content.ReadAsStringAsync();
  $success = $task.Wait(15000);
  if (!$success) {
    Write-Output $response;
  }

  ($($task.Result) | ConvertFrom-Json).value;
}

function Get-PortalLanguages {
  Param(
    [Parameter(Mandatory=$True)]
    $CrmClient
  )

  $languages = Get-PortalData -Path 'adx_portallanguages?$select=adx_portallanguageid,adx_languagecode' -CrmClient $CrmClient;
  @($languages | % { @{
    PortalLangaugeId = $_.adx_portallanguageid
    LanguageCode = $_.adx_languagecode
  } })
}

function Get-PortalWebsiteLanguages {
  Param(
    [Parameter(Mandatory=$True)]
    $CrmClient
  )

  $languages = Get-PortalData -Path 'adx_websitelanguages?$select=adx_websitelanguageid,_adx_websiteid_value,_adx_portallanguageid_value,adx_name' -CrmClient $CrmClient;
  @($languages | % { @{
    WebSiteLanguageId = $_.adx_websitelanguageid
    WebSiteId = $_._adx_websiteid_value
    PortalLanguageId = $_._adx_portallanguageid_value
    Name = $_.adx_name
  } })
}

function Get-PortalWebsites {
  Param(
    [Parameter(Mandatory=$True)]
    $CrmClient
  )

  $websites = Get-PortalData -Path 'adx_websites?$select=adx_websiteid,adx_name' -CrmClient $CrmClient;
  @($websites | % { @{
    WebSiteId = $_.adx_websiteid
    Name = $_.adx_name
  }  })
}

function Get-PortalWebFiles {
  Param(
    [Parameter(Mandatory=$True)]
    $CrmClient,
    [Parameter(Mandatory=$True)]
    $WebsiteId
  )

  $files = Get-PortalData -Path "annotations?`$select=annotationid,filename,_objectid_value,modifiedon,documentbody,mimetype,isdocument&`$expand=objectid_adx_webfile(`$select=_adx_websiteid_value,adx_name)&`$filter=(documentbody ne null and (endswith(filename, 'js') or endswith(filename, 'css'))) and objecttypecode eq 'adx_webfile' and isdocument eq true and (objectid_adx_webfile/_adx_websiteid_value eq $WebsiteId)" -CrmClient $CrmClient;
  @($files | % { @{
    AnnotationId = $_.annotationid
    ObjectId = $_._objectid_value
    Filename = $_.filename
    DocumentBody = $_.documentbody
    MimeType = $_.mimetype
    IsDocument = $_.isdocument
  } })
}

function Get-PortalWebPages {
  Param(
    [Parameter(Mandatory=$True)]
    $CrmClient,
    [Parameter(Mandatory=$True)]
    $WebsiteId
  )

  $pages = Get-PortalData -Path "adx_webpages?`$select=adx_webpageid,adx_name,adx_partialurl,adx_isroot,_adx_webpagelanguageid_value,_adx_parentpageid_value,_adx_websiteid_value,adx_copy,adx_customcss,adx_customjavascript&`$filter=(adx_websiteid/adx_websiteid eq $WebSiteId)&`$orderby=adx_isroot desc,adx_name asc" -CrmClient $CrmClient;
  @($pages | % { @{
    WebPageId = $_.adx_webpageid
    Name = $_.adx_name
    adx_partialurl = $_.adx_partialurl
    IsRoot = $_.adx_isroot
    WebPageLanguageId = $_._adx_webpagelanguageid_value
    ParentPageId = $_._adx_parentpageid_value
    WebsiteId = $_._adx_websiteid_value
    Copy = $_.adx_copy
    CustomCss = $_.adx_customcss
    CustomJavaScript = $_.adx_customjavascript
  } })
}

function Get-PortalTemplates {
  Param(
    [Parameter(Mandatory=$True)]
    $CrmClient,
    [Parameter(Mandatory=$True)]
    $WebsiteId
  )

  $templates = Get-PortalData -Path "adx_webtemplates?`$select=adx_webtemplateid,adx_name,adx_source&`$filter=(adx_websiteid/adx_websiteid eq $WebSiteId)&`$orderby=adx_name asc" -CrmClient $CrmClient;
  @($templates | % { @{
    WebTemplateId = $_.adx_webtemplateid
    Name = $_.adx_name
    Source = $_.adx_source
  } })
}

function Get-PortalContentSnippets {
  Param(
    [Parameter(Mandatory=$True)]
    $CrmClient,
    [Parameter(Mandatory=$True)]
    $WebsiteId
  )

  $snippets = Get-PortalData -Path "adx_contentsnippets?`$select=adx_name,_adx_contentsnippetlanguageid_value,adx_contentsnippetid,adx_value&`$filter=(_adx_websiteid_value eq $WebSiteId)&`$orderby=adx_name asc" -CrmClient $CrmClient;
  @($snippets | % { @{
    ContentSnippetId = $_.adx_contentsnippetid
    Name = $_.adx_name
    Value = $_.adx_value
    ContentSnippetLanguageId = $_._adx_contentsnippetlanguageid_value
  } })
}