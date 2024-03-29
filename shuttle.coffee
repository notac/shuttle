fs = require 'fs'
stream = require 'stream'

argv = require('minimist')(process.argv.slice(3))
bucket = 'location-shuttle'
prefix = argv['s3-prefix']

path = argv['path']
search_prefix = argv['search']

writer = new class extends stream.Writable
  constructor: (options) ->
    super(options)
    @s3 = new (require 'aws-sdk').S3({params: { Bucket: bucket } })
    
  write: (file, enc, done) ->
    $ = @

    console.log 'Initializing upload...'
    @s3.upload({Key: prefix+file, Body: fs.createReadStream(path+file) })
      .send (err, data) ->
        console.log 'Upload complete.'

        if err
          console.log "Couldn't upload: " + prefix+file + " " + err.message
          if done
            done()
        else
          fs.unlink path+file, (err) ->
            if err
              console.log "Couldn't remove log: " + err.message
            if done
              done()
        

if process.argv.length < 4
  console.log 'Missing path and prefix parameters'

fs.readdir path, (err, files) ->
  if err
    console.log "Couldn't read path: " + err.message
  else
    for file in files
      if file.startsWith(search_prefix)
        console.log 'Uploading file: ' + file
        writer.write file

    writer.end()
