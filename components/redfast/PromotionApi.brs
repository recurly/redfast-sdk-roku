' Copyright (C) 2023 Redfast Inc - All Rights Reserved
'
' Must not be copied and/or distributed without the express
' permission of Redfast Inc

sub init()
    m.ApiBaseUrl = "https://conduit.redfastlabs.com/"
    m.ApiProdBaseUrl = "https://conduit.redfast.com/"
end sub

sub fireEvent(params as Object)
    m.params = params
    m.top.functionName = "fireEventImpl"
    m.top.control = "run"
end sub

sub fireEventImpl()
    event = m.params.event
    baseUrl = m.ApiProdBaseUrl
    if m.top.environment = "staging"
        baseUrl = m.ApiBaseUrl
    end if
    if event = "ping" or event = "click" or event = "traitping"
        baseUrl += "ping"
    else if event = "impression"
        baseUrl += "paths/" + m.params.pathId + "/impression"
    else if event = "dismiss"
        baseUrl += "paths/" + m.params.pathId + "/dismiss"
    else if event = "goal"
        baseUrl += "paths/" + m.params.pathId + "/goal"
    else if event = "customTrack"
        baseUrl += "ping"
    else if event = "resetGoal"
        baseUrl += "paths/goal_reset_all"
    else if event = "holdout"
        baseUrl += "paths/" + m.params.pathId + "/holdout"
    end if

    connection = CreateObject("roUrlTransfer")
    connection.SetCertificatesFile("common:/certs/ca-bundle.crt")
    connection.AddHeader("X-Roku-Reserved-Dev-Id", "")
    connection.InitClientCertificates()
    connection.AddHeader("Connection", "keep-alive")
    connection.AddHeader("Content-Type", "application/json")
    connection.AddHeader("Accept", "*/*")
    connection.AddHeader("USER-ID", m.top.userId)
    if m.top.anonymous_user_id <> ""
        connection.AddHeader("ANONYMOUS-USER-ID", m.top.anonymous_user_id)
    end if

    urlParams = "?"
    waitingTime = 4000
    if event = "click"
        urlParams += "type=" + m.params.type + "&event=" + connection.Escape(m.params.eventName) + "&id=" + m.params.id + "&value=" + connection.Escape(m.params.value)
    else if event = "customTrack"
        urlParams += "type=custom&custom_field_id=" + connection.Escape(m.params.customFieldId) + "&id=" + m.top.appId
    else if event = "resetGoal"
        urlParams += "client_reset_complete=true&id=" + m.top.appId
    else if event = "holdout" or event = "impression" or event = "dismiss" or event = "goal"
        urlParams += "id=" + m.top.appId
        if m.params.actionGroupId <> ""
            urlParams += "&action_group_id=" + m.params.actionGroupId
        end if
        if event = "dismiss"
            urlParams += "&click=" + m.params.reason
        end if
        if event = "goal"
            if m.params.accept_type <> invalid
                urlParams += "&accept_type=" + m.params.accept_type
            end if
            if m.params.surveySelection <> invalid
                urlParams += "&survey_input_value=" + m.params.surveySelection
            end if
        end if
    else
        date = CreateObject("roDateTime")
        epoch = date.AsSeconds().toStr()
        urlParams += "id=" + m.top.appId + "&send_ts=" + epoch
        if event = "ping"
            di = CreateObject("roDeviceInfo")
            urlParams += "&event=" + m.params.name + "&type=screen&device_model=" + di.GetModel()
            if m.params.etag <> invalid
                connection.AddHeader("If-None-Match", m.params.etag)
            end if
        else if event = "traitping"
            for each key in m.params.keys()
                if key <> "event"
                    urlParams += "&properties[" + connection.Escape(key) + "]=" + connection.Escape(m.params[key])
                end if
            end for
        end if
    end if
    urlParams += "&device_type=" + m.top.deviceType

    fullUrl = baseUrl + urlParams
    port = CreateObject("roMessagePort")
    connection.SetPort(port)
    connection.SetUrl(fullUrl)
    print fullUrl + ": with user: " + m.top.userId + ", anonymous user id:" + m.top.anonymous_user_id
    if connection.AsyncGetToString()
        result = wait(waitingTime, port)
        if type(result) = "roUrlEvent"
            if event = "ping" or event = "holdout"
                statusCode = result.GetResponseCode()
                if statusCode = 200
                    jsonStr = result.GetString()
                    if jsonStr <> invalid and jsonStr.Len() > 0
                        json = ParseJson(jsonStr)
                        if json <> invalid
                            json.etag = result.GetResponseHeaders().Etag
                            m.top.content = json
                        else
                            m.top.content = invalid
                        end if
                    else
                        m.top.content = invalid
                    end if
                else if statusCode = 304
                    json = {}
                    json.etag = result.GetResponseHeaders().Etag
                    m.top.content = json
                else
                    m.top.content = invalid
                end if
            end if
        end if
    else
        print "AsyncGetToString failed"
    end if
end sub
