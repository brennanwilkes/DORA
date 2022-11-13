const fs = require("fs");
const config = JSON.parse(fs.readFileSync(process.argv[2], "utf-8"))
const exec = require("util").promisify(require("child_process").exec);

const REPO="brennanwilkes/dora";
const REPO_DIR=REPO.split("/")[1];
const INSTALL_SCRIPT=`https://raw.githubusercontent.com/${REPO}/main/install.sh`;
const CLONE_URL=`https://github.com/${REPO}.git`;

console.log(`Initializing ${config.workers.length} workers`);
console.log("Downloading and running install script");

Promise.all([...config.workers, config.scheduler].map(server => exec(
	`ssh -o StrictHostKeyChecking=accept-new -i ${server.key} ${server.user}@${server.ip} "curl -Ls ${INSTALL_SCRIPT} | bash"`,
	{stdio: "inherit"}
))).then((resp) => {
	console.log(`Cloning ${REPO} repo`);
	return Promise.all([...config.workers, config.scheduler].map(server => exec(
		`ssh -o StrictHostKeyChecking=accept-new -i ${server.key} ${server.user}@${server.ip} "[[ -d ${REPO_DIR} ]] && rm -rf "${REPO_DIR}" ; git clone ${CLONE_URL} && rm -rf ${REPO_DIR}/*.json ${REPO_DIR}/*.tf ${REPO_DIR}/README.md ${REPO_DIR}/initialize_compute_instances.js${server.ip === config.scheduler.ip ? "" : ` ${REPO_DIR}/add_to_result.js ${REPO_DIR}/minimize.js ${REPO_DIR}/result_combiner.js` }"`,
		{stdio: "inherit"}
	)));
}).then(() => {
	console.log(`Copying config file to scheduler`);
	return exec(`scp -o StrictHostKeyChecking=accept-new -i ${config.scheduler.key} ${process.argv[2]} ${config.scheduler.user}@${config.scheduler.ip}:${REPO_DIR}/`, {stdio: "inherit"});
}).then(() => {
	console.log(`Copying worker keys to scheduler`);
	return Promise.all(config.workers.map(server => exec(
		`scp -o StrictHostKeyChecking=accept-new -i ${config.scheduler.key} ${server.key} ${config.scheduler.user}@${config.scheduler.ip}:.ssh/${server.key.split("/").splice(-1)[0]}`,
		{stdio: "inherit"}
	)))
}).then(() => {
	console.log(`Copying scheduler key to workers`);
	return Promise.all(config.workers.map(server => exec(
		`scp -o StrictHostKeyChecking=accept-new -i ${server.key} ${config.scheduler.key} ${server.user}@${server.ip}:.ssh/${config.scheduler.key.split("/").splice(-1)[0]}`,
		{stdio: "inherit"}
	)))
}).then(() => {
	console.log(`Copying custom config files to workers`);
	return Promise.all(config.workers.map((server, i) => {
		const configForWorker = structuredClone(config);
		delete configForWorker.workers;
		delete configForWorker.scheduler;
		configForWorker.results = `results.json`;
		configForWorker.repos = configForWorker.repos.filter((_, j) => (j % config.workers.length) === i);
		console.log(`Distributing ${configForWorker.repos.length} repos to worker ${i} (${configForWorker.repos.map(r => r.id).join(", ")})`);
		fs.writeFileSync(`/tmp/configForWorker${i}.json`, JSON.stringify(configForWorker, null, 4));
		return exec(
			`scp -o StrictHostKeyChecking=accept-new -i ${server.key} /tmp/configForWorker${i}.json ${server.user}@${server.ip}:~/${REPO_DIR}/config.json`,
			{stdio: "inherit"}
		)
	}))
}).then(() => {
	console.log(`Copying data auth file to scheduler`);
	fs.writeFileSync(`/tmp/authDataFile.txt`,config.workers.map(w => `${w.ip},${w.user},${w.key}`).join("\n"));
	return exec(`scp -o StrictHostKeyChecking=accept-new -i ${config.scheduler.key} /tmp/authDataFile.txt ${config.scheduler.user}@${config.scheduler.ip}:${REPO_DIR}/`, {stdio: "inherit"});
}).then(() => {
	console.log("Compute instances initialized");
	console.log(`----------------------------`);
	console.log("To authenticate workers:")
	console.log(`ssh -i ${config.scheduler.key} ${config.scheduler.user}@${config.scheduler.ip} "~/${REPO_DIR}/authenticate_compute_instances.sh ${REPO_DIR}"`);
	// console.log(`ssh -i ${config.scheduler.key} ${config.scheduler.user}@${config.scheduler.ip}`);
	// console.log(`~/${REPO_DIR}/authenticate_compute_instances.sh ${REPO_DIR}`)
	console.log(`----------------------------`);
	console.log("To access scheduler:")
	console.log(`ssh -i ${config.scheduler.key} ${config.scheduler.user}@${config.scheduler.ip}`);
	console.log(`----------------------------`);
	console.log("To access workers:")
	config.workers.forEach((server, i) => {
		console.log(`ssh -i ${server.key} ${server.user}@${server.ip}`);
	});
	console.log(`----------------------------`);
	console.log(`To start workers:`);
	console.log(`ssh -i ${config.scheduler.key} ${config.scheduler.user}@${config.scheduler.ip} "~/${REPO_DIR}/start_compute_instances.sh '${REPO_DIR}' '${config.scheduler.user}' '${config.scheduler.ip}' '${config.scheduler.key}'"`)
	console.log(`----------------------------`);
	return Promise.resolve();
}).catch(console.error);
