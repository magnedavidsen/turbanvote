const express = require('express');
let app = express();
const expressWs = require('express-ws')(app);

app.get('/hello', function (req, res) {
  res.send('Hello World!');
})

app.post('/vote', function (req, res) {
    let ipAddr = req.headers["x-forwarded-for"];
    if (ipAddr){
        const list = ipAddr.split(",");
        ipAddr = list[list.length-1];
    } else {
        ipAddr = req.connection.remoteAddress;
    }

  res.send(ipAddr);
})

app.ws('/counter', function(ws, req) {

    var i = 0, howManyTimes = 10;
    const countObj = JSON.stringify([{"id": "1", "votes": 200, "name": "hmm"}, {"id": "2", "votes": 200, "name": "hmm"}, {"id": "3", "votes": 200, "name": "hmm"}]);
    function f() {
        ws.send(countObj);
        i++;
        if( i < howManyTimes ){
            setTimeout( f, 3000 );
        }
    }
    f();

});


app.post('/vote/:turban_id', function (req, res) {
  res.send('Got a POST request: ' + req.params.turban_id)
})

app.listen(3000, function () {
  console.log('Example app listening on port 3000!');
})
