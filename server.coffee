#!/usr/bin/env coffee

express = require('express')
morgan = require('morgan')
bodyParser = require('body-parser')
paths = require('./config.json').paths
child_process = require('child_process')
_ = require('lodash')
es = require('event-stream')
ansi_up = require('ansi_up')

app = express()

app.use([
    morgan('common'),
    express.static(paths.dest),
    bodyParser.urlencoded({ extended: false })
])

app.post('/rebuild', (req, res, next)->
    res.type('html')
    res.status(200)
    res.writeContinue()
    for i in [1..20]
        res.write("                                                  \n")
    res.write('<!DOCTYPE html><html><body><pre>')

    env = _.defaults(process.env, {
        DEBUG: 'gulp-spreadsheets,gulp-drive'
        DEBUG_COLORS: true
    })

    child = child_process.spawn('gulp', ['build', '--color'], {env: env})
    es.merge([child.stdout, child.stderr])
    .pipe(es.mapSync((text)->
        process.stderr.write(text)
        ansi_up.ansi_to_html(ansi_up.escape_for_html(''+text))
    ))
    .pipe(res)

    # support stopping the build if res.connection closes
    if req.body.stop_on_close
        res.on('close', ->
            child.kill('SIGHUP')
        )
)

app.post('/publish', (req, res, next)->
    res.status(501)
    res.end("not implemented")
)

module.exports = app

if module is require.main
    host = process.env.OPENSHIFT_NODEJS_IP || '0.0.0.0'
    port = process.env.OPENSHIFT_NODEJS_PORT || 8000
    server = app.listen(port, host, ->
        console.log("HTTP server started on port", this.address().port)
    )
