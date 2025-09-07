const net = require("net");

function checkPort(port) {
  return new Promise((resolve) => {
    const server = net.createServer();

    server.once("error", () => resolve(false)); // ใช้งานอยู่
    server.once("listening", () => {
      server.close();
      resolve(true); // ว่าง
    });

    server.listen(port);
  });
}

async function scanPorts(start, end) {
  for (let port = start; port <= end; port++) {
    const isFree = await checkPort(port);
    if (isFree) {
      console.log(`Port ${port} → FREE ✅`);
    } else {
      console.log(`Port ${port} → IN USE ❌`);
    }
  }
}

// ตัวอย่าง: เช็ค port 3000-10000
scanPorts(3000, 10000);
