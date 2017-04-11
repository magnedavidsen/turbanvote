const express = require('express');
const app = express();
const expressWs = require('express-ws')(app);

let turbans = [{"id": "1", "votes": 0, "name": "hmm"}, {"id": "2", "votes": 0, "name": "hmm"}, {"id": "3", "votes": 0, "name": "hmm"}];

app.use(express.static('public'));

app.ws('/counter', function(ws, req) {

    ws.on('message', function(msg) {
        const xfor = req.get('x-forwarded-for');
        console.log(req.headers);
        console.log(xfor);
        const nuturb = turbans.map(turban => {
            if(turban.id === msg) {
                turban.votes = turban.votes + 1;
            }
            return turban;
        });
        turbans = nuturb;
    });

    function f() {
        const countObj = JSON.stringify(turbans);
        ws.send(countObj, (error) => console.log("Web socket send error: " + error));
        setTimeout( f, 3000 );
    }
    f();
});

app.listen(3000);
