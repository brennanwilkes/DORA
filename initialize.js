const config = JSON.parse(require("fs").readFileSync(process.argv[2], "utf-8"))
const exec = require("util").promisify(require("child_process").exec);

const REPO="brennanwilkes/dora";
const REPO_DIR=REPO.split("/")[1];
const INSTALL_SCRIPT=`https://raw.githubusercontent.com/${REPO}/main/install.sh`;
const CLONE_URL=`https://github.com/${REPO}.git`;

Promise.all([...config.workers, config.scheduler].map(server => exec(
	`ssh -o StrictHostKeyChecking=accept-new -i ${server.key} ${server.user}@${server.ip} "curl -Ls ${INSTALL_SCRIPT} | bash"`,
	{stdio: "inherit"}
))).then((resp) => {
	return Promise.all([...config.workers, config.scheduler].map(server => exec(
		`ssh -o StrictHostKeyChecking=accept-new -i ${server.key} ${server.user}@${server.ip} "[[ -d ${REPO_DIR} ]] && rm -rf "${REPO_DIR}" ; git clone ${CLONE_URL}"`,
		{stdio: "inherit"}
	)));
}).then(() => {
	return exec(`scp -o StrictHostKeyChecking=accept-new -i ${config.scheduler.key} ${process.argv[2]} ${config.scheduler.user}@${config.scheduler.ip}:`, {stdio: "inherit"});
}).then(() => {
	return Promise.all(config.workers.map(server => exec(
		`scp -o StrictHostKeyChecking=accept-new -i ${config.scheduler.key} ${server.key} ${config.scheduler.user}@${config.scheduler.ip}:.ssh/${server.key.split("/").splice(-1)[0]}`,
		{stdio: "inherit"}
	)))
}).catch(console.error);
