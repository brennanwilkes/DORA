const fs = require("fs");
const config = JSON.parse(fs.readFileSync(process.argv[2], "utf-8"))
const exec = require("util").promisify(require("child_process").exec);

const REPO="brennanwilkes/dora";
const REPO_DIR=REPO.split("/")[1];
Promise.all(config.workers.map(server => {
	console.error(`Querying ${server.ip}`);
	return exec(`ssh -o StrictHostKeyChecking=accept-new -i ${server.key} ${server.user}@${server.ip} "cd ${REPO_DIR} ; cat stdout.txt"`).then(promise => {
		console.error(`Completed ${server.ip}`);
		return Promise.resolve(promise);
	})
})).then(results => {
	results.forEach((output, i) => {
		console.log(output.stdout);
		if(output.stderr && output.stderr.length > 2){
			console.error(output.stderr);
		}
	});
});
Promise.all(config.workers.map(server => {
	console.error(`Querying ${server.ip}`);
	return exec(`ssh -o StrictHostKeyChecking=accept-new -i ${server.key} ${server.user}@${server.ip} "cd ${REPO_DIR} ; cat worker.err"`).then(promise => {
		console.error(`Completed ${server.ip}`);
		return Promise.resolve(promise);
	})
})).then(results => {
	results.forEach((output, i) => {
		console.error(`========================= ${i} ===========================`);
		console.error(output.stdout);
		if(output.stderr && output.stderr.length > 2){
			console.error(output.stderr);
		}
		console.error(`=======================================================`);
	});
});
