const express = require('express');
const { spawn } = require('child_process');
const app = express();
const http = require('http').createServer(app);
const io = require('socket.io')(http);
const fs = require('fs');

app.use(express.static(__dirname + '/public'));

app.get('/', (req, res) => {
  res.sendFile(__dirname + '/index.html');
});

let tcpdumpProcess;
let pcapFile;

io.on('connection', (socket) => {
  socket.on('start', ({ filename, saveToFile }) => {
    if (tcpdumpProcess) return;

    if (saveToFile) {
      const newOutputFilename = filename.trim();

      if (newOutputFilename !== '') {
        pcapFile = fs.createWriteStream(`${newOutputFilename}.pcap`, { flags: 'a' });
      } else {
        socket.emit('output', 'Please enter a valid file name.');
        return;
      }
    }

    socket.emit('output', 'Packet capturing started:\n\n');

    tcpdumpProcess = spawn('tcpdump', ['-l', '-i', 'tun0', '-n', 'ip']);
    if (saveToFile) {
      tcpdumpProcess.stdout.pipe(pcapFile);
    }

    tcpdumpProcess.stdout.on('data', (data) => {
      socket.emit('output', data.toString());
    });

    tcpdumpProcess.stderr.on('data', (data) => {
      console.error(`tcpdump stderr: ${data}`);
    });

    tcpdumpProcess.on('close', (code) => {
      console.log(`tcpdump process exited with code ${code}`);
      socket.emit('output', 'tcpdump process has stopped.\n\n\n');
      tcpdumpProcess = null;
      if (pcapFile) {
        pcapFile.end();
        pcapFile = null;
      }
    });
  });

  socket.on('stop', () => {
    if (tcpdumpProcess) {
      tcpdumpProcess.kill();
      tcpdumpProcess = null;
      if (pcapFile) {
        pcapFile.end();
        pcapFile = null;
      }
    }
  });
});

http.listen(3032, () => {
  console.log('Server listening on http://localhost:3032');
});
