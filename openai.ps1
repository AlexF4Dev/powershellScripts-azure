<#
.SYNOPSIS
    This script is a wrapper for the OpenAI API. It sends a message to the API and returns the response.
.DESCRIPTION
    This script is a wrapper for the OpenAI API. It sends a message to the API and returns the response.
    The script requires an API key to be set in the environment variable OPENAI_API_KEY or passed as a parameter.
    The script also requires the message to be sent to the API to be passed as a parameter.
    The script uses the Invoke-RestMethod cmdlet to make the API request.
    The response from the API is then output to the console.
    The script also logs the response to a file if a log file is specified.
.NOTES
    File Name      : openai.ps1
    Author         : Jagilber
    version: 240518

    https://platform.openai.com/docs/api-reference/models
    https://platform.openai.com/docs/guides/prompt-engineering
      Tactics:

      Include details in your query to get more relevant answers
      Ask the model to adopt a persona
      Use delimiters to clearly indicate distinct parts of the input
      Specify the steps required to complete a task
      Provide examples
      Specify the desired length of the output

      Instruct the model to answer using a reference text
      Instruct the model to answer with citations from a reference text

      Instruct the model to work out its own solution before rushing to a conclusion
      Use inner monologue or a sequence of queries to hide the model's reasoning process
      Ask the model if it missed anything on previous passes

      When using the OpenAI API chat completion, you can use various message roles to structure the conversation. The choice of roles depends on the context and your specific use case. However, here are ten commonly used message roles:

      1. system: Used for initial instructions or guidance for the assistant.
      2. user: Represents user input, questions, or instructions.
      3. assistant: Represents the assistant's responses or actions.
      4. developer: Used for presenting high-level instructions to the assistant.
      5. customer: Represents a customer or end-user in a customer support scenario.
      6. support: Represents a support agent in a customer support scenario.
      7. manager: Represents a manager or team lead providing instructions or guidance.
      8. reviewer: Used for providing feedback on the assistant's responses or behavior.
      9. colleague: Represents a colleague or team member in a collaboration scenario.
      10. expert: Represents a subject matter expert providing specific domain knowledge.
    response:
    {
      "id": "chatcmpl-....",
      "object": "chat.completion",
      "created": 1706976614,
      "model": "gpt-3.5-turbo-0613",
      "choices": [
        {
          "index": 0,
          "message": "@{role=assistant; content=I'm sorry, I am an AI and do not have the capability to know the current time. Please check your device or a reliable source for the accurate time.}",
          "logprobs": null,
          "finish_reason": "stop"
        }
      ],
      "usage": {
        "prompt_tokens": 12,
        "completion_tokens": 33,
        "total_tokens": 45
      },
      "system_fingerprint": null
    }

.EXAMPLE
    .\openai.ps1 -prompts 'can you help me with a question?'
.EXAMPLE
    .\openai.ps1 -prompts 'can you help me with a question?' -apiKey '<your-api-key>'
.EXAMPLE
    .\openai.ps1 -prompts 'can you help me with a question?' -apiKey '<your-api-key>' -promptRole 'user'
.EXAMPLE
    .\openai.ps1 -prompts 'can you help me with a question?' -apiKey '<your-api-key>' -promptRole 'user' -model 'gpt-4'
.PARAMETER prompts
    The message to send to the OpenAI API.
.PARAMETER apiKey
    The API key to use for the OpenAI API. If not specified, the script will attempt to use the environment variable OPENAI_API_KEY.
.PARAMETER promptRole
    The role of the message to send to the OpenAI API. This can be either 'system' or 'user'. The default is 'system'.
.PARAMETER model
    The model to use for the OpenAI API. This can be either 'gpt-3.5-turbo', 'gpt-3.5-turbo-0613', 'gpt-4-turbo', or 'gpt-4'. The default is 'gpt-3.5-turbo'.
.PARAMETER logFile
    The log file to write the response from the OpenAI API to. If not specified, the response will not be logged.
.PARAMETER promptsFile
    The file to store the conversation history. If not specified, the conversation history will not be stored.  
.PARAMETER seed
    The seed to use for the OpenAI API. The default is the process ID of the script.
.PARAMETER newConversation
    If specified, the conversation history will be reset.
.PARAMETER completeConversation
    If specified, the conversation history will not be saved.
.PARAMETER logProbabilities
    If specified, the log probabilities will be included in the response.
.PARAMETER systemPrompts
    The system prompts to use for the OpenAI API. If not specified, the default system prompts will be used.

.LINK
    [net.servicePointManager]::Expect100Continue = $true;[net.servicePointManager]::SecurityProtocol = [net.SecurityProtocolType]::Tls12;
    invoke-webRequest "https://raw.githubusercontent.com/jagilber/powershellScripts/master/openai.ps1" -outFile "$pwd\openai.ps1";
    write-host 'set api key in environment variable OPENAI_API_KEY or pass as parameter'
    .\openai.ps1 'can you help me with a question?'

#>
[cmdletbinding()]
param(
  [string[]]$prompts = @(),
  [string]$apiKey = "$env:OPENAI_API_KEY", 
  [ValidateSet('user', 'system', 'assistant', 'user', 'function', 'tool')]
  [string]$promptRole = 'user', 
  [ValidateSet('https://api.openai.com/v1/chat/completions', 'https://api.openai.com/v1/images/completions', 'https://api.openai.com/v1/davinci-codex/completions')]
  [string]$endpoint = '', #'https://api.openai.com/v1/chat/completions',
  # [ValidateSet('chat', 'images', 'davinci-codex','custom')]
  # [string]$script:endpointType = 'chat',
  [ValidateSet('gpt-3.5-turbo-1106', 'gpt-4-turbo', 'dall-e-2', 'dall-e-3', 'davinci-codex-003', 'gpt-4o', 'gpt-4o-2024-05-13')]
  [string]$model = 'gpt-4o',
  [string]$logFile = "$psscriptroot\openai.log",
  [string]$promptsFile = "$psscriptroot\openaiMessages.json",
  [int]$seed = $pid,
  [switch]$continueConversation,
  [switch]$newConversation = !$continueConversation,
  [switch]$completeConversation,
  [bool]$logProbabilities = $false,
  [string]$imageQuality = 'hd',
  [int]$imageCount = 1, # n
  [switch]$imageEdit, # edit image
  [string]$imageFilePng = "$psscriptroot\downloads\openai.png", #"$pwd\openai-$((get-date).tostring('yyMMdd-HHmmss')).png)", # png file to upload and edit . 4mb max with transparency layer and square aspect ratio
  [ValidateSet('256x256', '512x512', '1024x1024', '1792x1024', '1024x1792')]
  [string]$imageSize = '1024x1024', # dall-e 2 only supports up to 512x512
  [ValidateSet('vivid', 'natural')]
  [string]$imageStyle = 'vivid',
  [string]$outputPath = "$psscriptroot\output",
  [string]$user = 'default',
  [ValidateSet('url', 'b64_json')]
  [string]$imageResponseFormat = 'url',
  [ValidateSet('json', 'markdown')]
  [string]$responseFileFormat = 'markdown',
  [ValidateSet('json_object', 'text')]
  [string]$responseFormat = 'json_object',
  [string[]]$systemPrompts = @(
    'use chain of thought reasoning to break down and step through the prompts thoroughly, reiterating for precision when generating a response.',
    'prefer accurate and complete responses including any references and citations',
    'use github.com, stackoverflow.com, microsoft.com, azure.com, openai.com, grafana.com, wikipedia.com, associatedpress.com, reuters.com, referencesource.microsoft.com and other reliable sources for the response'
  ),
  [switch]$listAssistants,
  [switch]$listModels,
  [switch]$whatIf,
  [switch]$init
)

[ValidateSet('chat', 'images', 'davinci-codex', 'custom')]
[string]$script:endpointType = 'chat'
$script:messageRequests = [collections.arraylist]::new()
$script:systemPromptsList = [collections.arraylist]::new($systemPrompts)
$variableExclusions = @('PS*', '?', 'Host', 'HOME', 'input', 'MyInvocation', 'variableExclusions', 'false', 'true', 'Is*', '*Experimental*', 'apiKey')

# Enumerate all parameters
if (!$global:ai -or $init) {
  $global:ai = [ordered]@{}
}

foreach ($name in $PSBoundParameters.Keys) {
  $value = $PSBoundParameters[$name]
  write-host "$name = $value"
  $global:ai[$name] = $value
}
  
function main() {
  if (!(set-variables)) {
    return
  }
  
  $startTime = Get-Date
  $messages = @()
  write-log "===================================="
  write-log ">>>>starting openAI chat request $startTime<<<<" -color White
  
  if (!$apiKey) {
    write-log "API key not found. Please set the OPENAI_API_KEY environment variable or pass the API key as a parameter." -color Red
    return
  }

  if ($responseFormat -imatch 'json') {
    $script:systemPromptsList.add(' always reply in json format.')
  }
  
  if ($responseFileFormat -ieq 'markdown') {
    $script:systemPromptsList.add(' format reply message content in github markdown format.')
    $markdownJsonSchema = convert-toJson @{
      markdown = @{
        content    = '<markdown content>'
        name       = '<github compliant markdown file name with dashes and extension>'
        references = @(
          @{
            name = '<reference name>'
            url  = '<reference url>'
          }
        )
      }      
    }
  
    $script:systemPromptsList.add(' json_object response schema:' + $markdownJsonSchema)
    $script:systemPromptsList.add(' include the markdown content directly ready for presentation.')
  }

  if ($imageFilePng -and !(test-path ([io.path]::GetDirectoryName($imageFilePng)))) {
    write-log "creating directory: [io.path]::GetDirectoryName($imageFilePng)" -color Yellow
    mkdir -Force ([io.path]::GetDirectoryName($imageFilePng))
  }

  $endpoint = get-endpoint #$script:endpointType $endpoint
  
  if ($newConversation -and (Test-Path $promptsFile)) {
    write-log "resetting context" -color Yellow
    write-log "deleting messages file: $promptsFile" -color Yellow
    Remove-Item $promptsFile
  }
  
  if (Test-Path $promptsFile) {
    write-log "reading messages from file: $promptsFile" -color Yellow
    [void]$script:messageRequests.AddRange(@(Get-Content $promptsFile | ConvertFrom-Json))
  }

  $headers = @{
    'Authorization' = "Bearer $apiKey"
    'Content-Type'  = 'application/json'
    'OpenAI-Beta'   = 'assistants=v1'
  }
  if ($endpointType -eq 'images') {
    $headers.'Content-Type' = 'multipart/form-data'
    #$headers.Add('Accept', 'image/png')
  }

  $requestBody = build-requestBody $script:messageRequests $script:systemPromptsList

  # Convert the request body to JSON
  $jsonBody = convert-toJson $requestBody

  if ($listModels) {
    write-log "listing models" -color Yellow
    $response = invoke-rest 'https://api.openai.com/v1/models' $headers
    write-log "models: $(convert-toJson $response)" -color Yellow
    return
  }

  if ($listAssistants) {
    write-log "listing assistants" -color Yellow
    $response = invoke-rest 'https://api.openai.com/v1/assistants?limit=100' $headers
    write-log "assistants: $(convert-toJson $response)" -color Yellow
    return
  }
  
  # Make the API request using Invoke-RestMethod
  $response = invoke-rest $endpoint $headers $jsonBody
  $message = read-messageResponse $response $script:messageRequests
  code (save-MessageResponse $message.content)

  $global:openaiResponse = $response
  $global:message = $message
  write-log "api response stored in global variables: `$global:openaiResponse and `$global:message" -ForegroundColor Cyan

  if ($logFile) {
    write-log "result appended to logfile: $logFile"
  }

  # Write the assistant response to the log file for future reference

  if (!$completeConversation -and $promptsFile) {
    # $script:messageRequests += $message
    convert-toJson $script:messageRequests | Out-File $promptsFile
    write-log "messages stored in: $promptsFile" -ForegroundColor Cyan  
  }

  write-log "response:$(convert-toJson ($message.content | convertfrom-json))" -color Green
  write-log ($global:openaiResponse | out-string) -color DarkGray
  write-log "use alias 'ai' to run script with new prompt. example:ai '$($prompts[0])'" -color DarkCyan
  write-log ">>>>ending openAI chat request $(((get-date) - $startTime).TotalSeconds.ToString("0.0")) seconds<<<<" -color White
  write-log "===================================="
  return #$message.content
}

function build-requestBody($messageRequests, $systemPrompts) {
  switch -Wildcard ($script:endpointType) {
    'chat' {
      $requestBody = build-chatRequestBody $messageRequests $systemPrompts
    }
    'images' {
      $requestBody = build-imageRequestBody $messageRequests $systemPrompts
    }
    'davinci-codex' {
      $requestBody = build-codexRequestBody $messageRequests $systemPrompts
    }
  }
  write-log "request body: $(convert-toJson $requestBody)" -color Yellow
  return $requestBody
}

function build-chatRequestBody($messageRequests, $systemPrompts) {
  if (!$messageRequests) {
    foreach ($message in $systemPrompts) {
      [void]$messageRequests.Add(@{
          role    = 'system'
          content = $message
        })
    }
  }

  foreach ($message in $prompts) {
    [void]$messageRequests.Add(@{
        role    = $promptRole
        content = $message
      })
  }

  $requestBody = @{
    response_format = @{ 
      type = $responseFormat
    }
    model           = $model
    seed            = $seed
    logprobs        = $logProbabilities
    messages        = $messageRequests.toArray()
    user            = $user
  }

  return $requestBody
}

function build-codexRequestBody($messageRequests) {
  throw "model $model not supported"
  $requestBody = @{
    model    = $model
    seed     = $seed
    logprobs = $logProbabilities
    messages = $script:messageRequests.toArray()
    user     = $user
  }

  return $requestBody
}

function build-imageRequestBody($messageRequests) {
  $messageRequests.AddRange($prompts)
  if ($imageEdit) {
    if (!(Test-Path $imageFilePng)) {
      throw "image file not found: $imageFilePng"
    }
    $requestBody = @{
      model           = $model
      prompt          = [string]::join('. ', $messageRequests.ToArray())
      n               = $imageCount
      response_format = $imageResponseFormat
      size            = $imageSize
      user            = $user
      image           = $imageFilePng # to-base64StringFromFile $imageFilePng
    }
  }
  else {
    $requestBody = @{
      model           = $model
      prompt          = [string]::join('. ', $messageRequests.ToArray())
      quality         = $imageQuality
      n               = $imageCount
      response_format = $imageResponseFormat
      size            = $imageSize
      style           = $imageStyle
      user            = $user
    }
  }
  return $requestBody
}

function convert-toJson($object, $depth = 5) {
  return convertto-json -InputObject $object -depth $depth -WarningAction SilentlyContinue
}

function get-endpoint() {
  #($script:endpointType, $endpoint) {
  switch -Wildcard ($model) {
    'gpt-*' {
      $endpoint = 'https://api.openai.com/v1/chat/completions'
      $script:endpointType = 'chat'
    }
    'dall-e-*' {
      $endpoint = 'https://api.openai.com/v1/images/generations'
      $script:endpointType = 'images'
      if ($imageEdit) {
        $endpoint = 'https://api.openai.com/v1/images/edits'
      }
    }
    'codex-*' {
      $endpoint = 'https://api.openai.com/v1/davinci-codex/completions'
      $script:endpointType = 'davinci-codex'
    }
    default {
      #$endpoint = 'https://api.openai.com/v1/chat/completions'
      $script:endpointType = 'custom'
    }
  }
  write-log "using endpoint: $endpoint" -color Yellow
  return $endpoint
}

function invoke-rest($endpoint, $headers, $jsonBody = $null) {
  if (!$whatIf -and $jsonBody) {
    write-log "invoke-restMethod -Uri $endpoint -Headers $(convert-toJson $headers) -Method Post -Body $jsonBody" -color Cyan
    $response = invoke-restMethod -Uri $endpoint -Headers $headers -Method Post -Body $jsonBody
  }
  elseif (!$whatIf) {
    write-log "invoke-restMethod -Uri $endpoint -Headers $(convert-toJson $headers) -Method Get" -color Cyan
    $response = invoke-restMethod -Uri $endpoint -Headers $headers -Method Get
  }

  write-log (convert-toJson $response) -color Magenta
  $global:openaiResponse = $response
  return $response
}
function read-messageResponse($response, [collections.arraylist]$messageRequests) {
  # Extract the response from the API request
  write-log $response

  switch ($script:endpointType) {
    'chat' {
      $message = $response.choices.message
      $messageRequests += $message
      if ($message.content) {
        $error.Clear()
        if (($messageObject = convertfrom-json $message.content -AsHashtable) -and !$error) {
          write-log "converting message content from json to compressed json" -color Yellow
          $message.content = (convert-toJson $messageObject -depth 99)
        }
      }
    }
    'images' {
      $message = $response.data
      if ($response.data.revised_prompt) {
        write-log "revised prompt: $($response.data.revised_prompt)" -color Yellow
        $messageRequests.Clear()
        $messageRequests.Add($response.data.revised_prompt)
      }
      if ($response.data.url) {
        write-log "downloading image: $($response.data.url)" -color Yellow
        write-host "invoke-webRequest -Uri $($response.data.url) -OutFile $imageFilePng"
        invoke-webRequest -Uri $response.data.url -OutFile $imageFilePng
        
        $tempImageFile = $imageFilePng.replace(".png", "$(get-date -f 'yyMMdd-HHmmss').png")
        writ-log "copying image to $tempImageFile" -color Yellow
        Copy-Item $imageFilePng $tempImageFile
        code $tempImageFile
      }

      $message | add-member -MemberType NoteProperty -Name 'content' -Value $message.url
    }
    'davinci-codex' {
      throw "model $model not supported"
    }
    default {
      write-log "unknown endpoint type: $script:endpointType" -color Red
    }
  }

  write-log "message: $(convert-toJson $message)" -color Yellow  
  return $message
}

function save-MessageResponse($message) {
  $responseExtension = 'json'
  $baseFileName = "openai-$(get-date -f 'yyMMddHHmmss')"
  $responseFile = "$outputPath\$baseFileName"
  
  if ($responseFileFormat -ieq 'markdown') {
    $responseExtension = 'md'
    $response = convertfrom-json $message -AsHashtable
    $message = $response.markdown.content
    if ($response.markdown.name) {
      $responseFile = "$outputPath\$baseFileName-$($response.markdown.name.trimend($responseExtension))"
    }
  }
  
  write-log "saving markdown response to $responseFile.$responseExtension" -color Magenta
  $message | out-file -FilePath "$responseFile.$responseExtension"
  copy-item "$responseFile.$responseExtension" "$baseFileName.$responseExtension" -force
  return "$responseFile.$responseExtension"
}

function set-variables() {
  write-log "set-alias ai $($MyInvocation.ScriptName)"
  set-alias ai $MyInvocation.ScriptName -scope global
  set-alias openai $MyInvocation.ScriptName -scope global


  #$variables = get-variable -scope script -exclude @('PS*','?','Host','HOME','input','MyInvocation','variableExclusions')
  # foreach ($variable in get-variable -scope script -exclude $variableExclusions) {
  #   $global:ai[$variable.Name] = $variable.Value
  #   # write-log "$($variable.Name): $($variable.Value)"
  # }

  if ($init) {
    write-log "variables: $(convert-toJson $global:ai -depth 1)" -color Green
    write-log "ai initialized" -color Green
    return $false
  }

  return $true
}

function to-FileFromBase64String($base64) {
  $bytes = [convert]::FromBase64String($base64)
  $file = [io.path]::GetTempFileName()
  [io.file]::WriteAllBytes($file, $bytes)
  return $file
}

function to-base64StringFromFile($file) {
  $bytes = [io.file]::ReadAllBytes($file)
  $base64 = [convert]::ToBase64String($bytes)
  return $base64
}

function write-log($message, [switch]$verbose, [ConsoleColor]$color = 'White') {
  $message = "$(get-date) $message"
  if ($logFile) {
    # Write the message to a log file
    $message | out-file -FilePath $logFile -Append
  }

  if ($verbose) {
    write-verbose $message
  }
  else {
    write-host $message -ForegroundColor $color
  }
}

main
