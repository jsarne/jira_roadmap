curl -s -D- -u 'user:pass' -X GET -H "Content-Type: application/json" 'https://govdelivery.atlassian.net/rest/api/2/search?jql=project=PM+and+type=Epic+and+resolution=unresolved+and+component=roadmap&fields=id,key,summary,customfield_11950,customfield_11951' | pretty_json.rb 