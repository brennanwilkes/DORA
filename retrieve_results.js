const fs = require("fs");
const config = JSON.parse(fs.readFileSync(process.argv[2], "utf-8"))
const exec = require("util").promisify(require("child_process").exec);

PATH=`./results3/`;
if(!fs.existsSync(PATH)){
	fs.mkdirSync(PATH);
}

const REPO="brennanwilkes/dora";
const REPO_DIR=REPO.split("/")[1];
Promise.all(config.workers.map(server => {
	console.error(`Querying ${server.ip}`);
	return exec(`scp -o StrictHostKeyChecking=accept-new -i ${server.key} '${server.user}@${server.ip}:~/${REPO_DIR}/*results*json' ${PATH} `).then(promise => {
		console.error(`Completed ${server.ip}`);
		return Promise.resolve(promise);
	})
}));
