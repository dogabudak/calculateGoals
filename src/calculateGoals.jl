import JSON

using Mongoc

using HTTP
using Sockets
using JSON

client = Mongoc.Client("mongodb://localhost:27017")
database = client["yesildoga"]
goalsCollection = database["goals"]
contributionsCollection = database["contributions"]

function getCampaign(req::HTTP.Request)
    projectId = HTTP.URIs.splitpath(req.target)[1]
    remaining = 0
    for document in Mongoc.find(goalsCollection, Mongoc.BSON("""{ "goalAchieved": false, "projectId":\"$projectId\" }"""))
        eachProject = Mongoc.as_json(document)
        projectAsJson = JSON.parse(eachProject)
        projectName= projectAsJson["projectName"]
        bson_pipeline = Mongoc.BSON( """[{ "\$match" : { "projectId" : \"$projectId\" } },{ "\$group" : {"_id" : "\$projectName", "total" : { "\$sum" : "\$amount" } } }]""")
       for doc in Mongoc.aggregate(contributionsCollection, bson_pipeline)
            totalContributions = Mongoc.as_json(doc)
            totalContributionsAsJson = JSON.parse(totalContributions)
            remaining = totalContributionsAsJson["total"]
       end
    end
    return HTTP.Response(200, string(remaining))
end

const ROUTER = HTTP.Router()
HTTP.@register(ROUTER, "GET", "/*", getCampaign)
HTTP.serve(ROUTER, ip"127.0.0.1", 8081)
