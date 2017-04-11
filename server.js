const express = require('express');
const app = express();
const expressWs = require('express-ws')(app);
const pool = require('./db');

let turbans = [];
const port = process.env.PORT || 3000;

app.use(express.static('public'));

app.ws('/counter', function(ws, req) {
    ws.on('message', function(msg) {
        const xfor = req.get('x-forwarded-for') || "No IP";
        pool.query('INSERT INTO votes (turban, ip) VALUES ($1, $2)', [msg, xfor]);

        turbans = turbans.map(turban => {
            if(turban.id === msg) turban.count = turban.count + 1;
            return turban;
        });
    });

    function f() {
        const countObj = JSON.stringify(turbans);
        ws.send(countObj, (error) => console.log("Web socket send error: " + error));
        setTimeout( f, 2000 );
    }
    f();
});

pool.query('select turbans.id, turbans.name, count(*)::int from turbans left join votes on votes.turban = turbans.id group by turbans.id')
  .then(function(res) {
      turbans = res.rows;
      app.listen(port, function() {
          console.log('server is listening on ' + port)
      });
});
