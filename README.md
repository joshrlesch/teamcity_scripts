## teamcity_scripts

### Build duration
This script will take a list of build configs and get the average build times for each config and display them in a formated console table.

This needs a local `secret.json` file is a format of
```json
{
	"username": "<username>", 
    "password": "<password>",
    "teamcity_url": "http://<teamcity-url>",
	"build_configs": [
						"<build-config-id-1>", 
						"<build-config-id-2"
					 ]
}
```

Run script with `ruby build_duration.rb` from the root of repo
