' Copyright (C) 2020 Recurly, Inc - All Rights Reserved
'
' Must not be copied and/or distributed without the express
' permission of Recurly, Inc

sub init()
    m.BEARER = "Bearer c405ed357f5046964ad69f1b5f45df7da5a03913af05cf685612a724bd5e48ed"
    m.BASE_URL = "https://api.webflow.com/v2"
end sub

sub getMovies(params as Object)
    m.top.functionName = "getMoviesImpl"
    m.top.control = "run"
end sub

function makeUrl(api as string) as object
    urlString = m.BASE_URL + api
    connection = CreateObject("roUrlTransfer")
    connection.SetCertificatesFile("common:/certs/ca-bundle.crt")
    connection.AddHeader("X-Roku-Reserved-Dev-Id", "")
    connection.InitClientCertificates()
    connection.AddHeader("Content-Type", "application/json")
    connection.AddHeader("Accept", "*/*")
    connection.AddHeader("Connection", "keep-alive")
    connection.AddHeader("Authorization", m.BEARER)
    port = CreateObject("roMessagePort")
    connection.SetPort(port)
    connection.SetUrl(urlString)
    if connection.AsyncGetToString()
        event = wait(10000, port)
        if type(event) = "roUrlEvent"
            if event.GetResponseCode() = 200
                json = event.GetString()
                return ParseJson(json)
            else
                print event.GetFailureReason()
            end if
        end if
    else
        print "AsyncGetToString failed"
    end if
    return invalid
end function

sub getMoviesImpl()
    allCategory = makeUrl("/collections/635c3e79a327a5864dd7a7cc/items")
    if allCategory = invalid then return
    allMovies = makeUrl("/collections/635c3e79a327a596b2d7a7cd/items")
    if allMovies = invalid then return

'    root = createObject("RoSGNode", "ContentNode")
'    for i = 0 to allCategory.items.count() - 1 step 1
'        category = allCategory.items[i]
'        categoryNode = root.createChild("ContentNode")
'        categoryNode.title = category.name
'        for j = 0 to allMovies.items.count() - 1 step 1
'            movie = allMovies.items[j]
'            if movie.category = category._id
'                movieNode = categoryNode.createChild("ContentNode")
'                movieNode.title = movie.name
'                movieNode.ContentType = "movie"
'                movieNode.description = movie["short-description"]
'                movieNode.HDPOSTERURL = movie["thumbnail-image"]["url"]
'            end if
'        end for
'    end for
    root = createObject("RoSGNode", "ContentNode")
    for j = 0 to allMovies.items.count() - 1 step 1
        movie = allMovies.items[j]["fieldData"]
        movieNode = root.createChild("ContentNode")
        movieNode.ContentType = "movie"
        movieNode.title = movie["name"]
        movieNode.Directors = [movie["director"]]
        movieNode.ShortDescriptionLine2 = movie["duration"]
        movieNode.description = movie["short-description"]
        movieNode.HDPOSTERURL = movie["thumbnail-image"]["url"]
        movieNode.SDPOSTERURL = movie["thumbnail-landscape"]["url"]
        movieNode.HDPOSTERURL = movie["thumbnail-portrait"]["url"]
    end for
    m.top.content = root
end sub