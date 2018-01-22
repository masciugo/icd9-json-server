# Icd9 json server setup

A local dokerized service for icd9 codes

1. Download icd9 official files from [official source](https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Publications/ICD9-CM/2011/)
2. Convert RTF original file to TXT

	`textutil -convert txt Dtab12.rtf`

3. jsonfy TXT file

  `ruby jsonify-icd9.rb Dtab12.txt`

4. Download json-server docker image

  `docker pull clue/json-server`

5. Run json-server locally

  `docker run -d --name icd9-json-server -p 80:80 -v \`pwd\`/Dtab12.json:/data/db.json clue/json-server`

6. Run queries like

```
  http://localhost/chapters
  http://localhost/chapters/1
  http://localhost/chapters/1/subchapters
  http://localhost/chapters/1/diseases
  http://localhost/subchapters
  http://localhost/subchapters/1/diseases
  http://localhost/subchapters/1/diseases?_page=1&_limit=20
  http://localhost/diseases?q=reflux
```

`http://localhost/chapters/1/subchapters/2` <= not working! [too deepness for json-server](https://github.com/typicode/json-server/issues/72)

## Deploy on heroku

```
heroku container:login
heroku create icd9-json-server # create the app ifbnecessary
heroku container:push web -a icd9-json-server
logs -tail -a icd9-json-server
```
