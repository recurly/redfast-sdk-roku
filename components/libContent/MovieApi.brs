' Copyright (C) 2020 Recurly, Inc - All Rights Reserved
'
' Must not be copied and/or distributed without the express
' permission of Recurly, Inc

sub init()
    m.API_KEY = "e3b287b40edd5313ba5318db511ee52a"
    m.BASE_URL = "https://api.themoviedb.org/3"
    m.IMAGE_BASE_URL = "https://image.tmdb.org/t/p/w300/"
end sub

sub getMovies(params as Object)
    m.top.functionName = "getMoviesImpl"
    m.top.control = "run"
end sub

function makeUrl(api as string) as object
    urlString = m.BASE_URL + api
    urlString += "?api_key=" + m.API_KEY + "&language=en-US"
    connection = CreateObject("roUrlTransfer")
    connection.SetCertificatesFile("common:/certs/ca-bundle.crt")
    connection.AddHeader("X-Roku-Reserved-Dev-Id", "")
    connection.InitClientCertificates()
    connection.AddHeader("Content-Type", "application/json")
    connection.AddHeader("Accept", "*/*")
    connection.AddHeader("Connection", "keep-alive")
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
    rootData = makeUrl("/genre/movie/list")
    if rootData = invalid then return

    for i = 0 to rootData.genres.count() - 1 step 1
        genre = rootData.genres[i]
        movies = makeUrl("/genre/" + str(genre.id).trim() + "/movies")
        if movies <> invalid
            genre.movies = movies
        end if
    end for

    shelfData = createObject("RoSGNode", "ContentNode")
    for i = 0 to rootData.genres.count() - 1 step 1
        genre = rootData.genres[i]
        collection = shelfData.createChild("ContentNode")
        collection.title = genre.name
        collection.ContentType = "movie"
        for j = 0 to genre.movies.results.count() - 1 step 1
            movie = genre.movies.results[j]
            meta = collection.createChild("ContentNode")
            meta.ContentType = "movie"
            if movie.poster_path <> invalid
                meta.HDPOSTERURL = m.IMAGE_BASE_URL + movie.poster_path
            end if
            meta.title = movie.title
            meta.description = movie.overview
        end for
    end for
    m.top.content = shelfData
end sub