# Using substitution variables to use in markdown
## manifest.json
Add the variable to the manifest.json file. This variable can then be referenced in the markdown.

**Example:**

manifest.json
```json
        {
          "title": "Provision using the OCI Console",
          "filename": "../provision-database/adb-provision-console.md",
          "db-name":"MYQUICKSTART"          
        }
```

markdown
```md
        {
          "title": "Provision using the OCI Console",
          "filename": "../provision-database/adb-provision-console.md",
          "db-name":"AAAMYQUICKSTART"          
        }
```


|variable|use|
|--------|---|
|db-name|database name|