'use strict';

const express = require('express');
const SocketServer = require('ws').Server;

const pool = require('./db');

const PORT = process.env.PORT || 3000;
let turbans = [];

const server = express()
    .use(express.static('public'))
    .listen(PORT, () => {
        pool.query('select turbans.id, turbans.name, count(*)::int from turbans left join votes on votes.turban = turbans.id group by turbans.id')
        .then((res) => turbans = res.rows);
        console.log(`Listening on ${ PORT }`)
    }
);

const wss = new SocketServer({ server });

wss.on('connection', (ws) => {
    console.log('Client connected');
    ws.on('close', () => console.log('Client disconnected'));
    ws.on('message', (msg) => {
        const xfor = ws.upgradeReq.headers['x-forwarded-for'] || "No IP";
        pool.query('INSERT INTO votes (turban, ip) VALUES ($1, $2)', [msg, xfor]);

        turbans = turbans.map(turban => {
            if(turban.id === msg) turban.count = turban.count + 1;
            return turban;
        });
    });
});

setInterval(() => {
    wss.clients.forEach((client) => {
      client.send(JSON.stringify(turbans));
    });
}, 1000);
