const fs = require("fs");
const util = require("util");
const exec = util.promisify(require("child_process").exec);

const fn = process.argv[2]

const config = JSON.parse(fs.readFileSync(fn, 'utf8'));
let completed = 0

const MINUTE = 60;
const HOUR = MINUTE * 60;
const DAY = HOUR * 24;
const WEEK = DAY * 7;
const YEAR = DAY * 365;
const MONTH = YEAR / 12;
const DeploymentFrequencyScale = [DAY, WEEK, MONTH, MONTH * 6];
const LeadTimeforChangesScale = [DAY, WEEK, MONTH, MONTH * 6];
const MeanTimetoRecoverScale = [HOUR, DAY, WEEK, MONTH];
const ChangeFailureRateScale = [0.15, 0.3, 0.45, 0.6];
const performer = (val, scale) => {
	if(val < scale[0]){
		return "Elite";
	}
	if(val < scale[1]){
		return "High";
	}
	if(val < scale[2]){
		return "Medium";
	}
	if(val < scale[3]){
		return "Low";
	}
	return "Critically Low";
}

console.log(`Starting study ${config.name} from ${config.start} to ${config.end}`)
Promise.all(config.repos.map(async (repo, i) => {
	console.log(`Analyzing ${repo.id} with deployment=${repo.deployment === 0 ? "releases" : "tags"}`);
	const startTime = Date.now();

	const analysis = await exec(`./analyze.sh ${repo.id} ${repo.deployment} "${config.end}" "${config.start}"`);
	if(analysis.stderr){
		return Promise.reject(new Error(analysis.stderr))
	}
	else{
		const data = analysis.stdout.split("\n");
		const numDeployments = parseInt(data[0].split(",")[3])
		const deploymentFrequency = parseInt(data[0].split(",")[4])
		const deployments = {}
		let totalCommits = 0;
		let totalDelta = 0;

		data.slice(1).filter(l => l.length > 1).forEach((line, i) => {
			line = line.split(",")
			const tag = line[1]
			const sha = line[2]
			const date = parseInt(line[3]);
			const delta = parseInt(line[5])
			if(!deployments[tag]){
				deployments[tag] = {commits:[], totalDelta: 0, averageDelta: 0}
			}

			deployments[tag].commits = [...deployments[tag].commits, sha]
			deployments[tag].totalDelta += delta;
			deployments[tag].date = date;
			deployments[tag].averageDelta = deployments[tag].totalDelta / deployments[tag].commits.length
			deployments[tag].hasFailure = false;
			deployments[tag].hasCriticalFailure = false;
			totalCommits += 1;
			totalDelta += delta;
		});

		let failures = []
		if(repo.failures?.type === 0){
			const jira = await exec(`./jira.sh "${repo.failures.url}" "${repo.failures.project}"`);
			if(jira.stderr){
				return Promise.reject(new Error(jira.stderr));
			}
			jiraData = JSON.parse(jira.stdout);
			failures = jiraData.issues.map((issue, i) => ({
				id: issue.key,
				critical: issue.fields.priority.name === "High" || issue.fields.priority.name === "Highest",
				version: issue.fields.fixVersions?.[0]?.name,
				resolved: new Date(issue.fields.fixVersions?.[0]?.releaseDate ?? issue.fields.resolutiondate).getTime() / 1000,
				created: new Date(issue.fields.created).getTime() / 1000
			})).map(failure => {
				let resolved;
				if(!failure.version){
					resolved = failure.resolved;
					const sorted = Object.keys(deployments).filter(k => deployments[k].date > failure.created).sort((a,b) => deployments[a].date - deployments[b].date);
					if(sorted.length > 0){
						console.log(sorted[0])
						failure.version = sorted[0];
					}
				}
				else{
					const tag = failure.version
					const stripped = tag.replace(/.*([0-9]+\.[0-9]+\.[0-9]+).*/,(m, $1) => $1);

					if(deployments[tag]){
						resolved = deployments[tag].date;
					}
					else if(deployments[stripped]){
						resolved = deployments[stripped].date;
					}
					else if(deployments[`v${stripped}`]){
						resolved = deployments[`v${stripped}`].date;
					}
					else{
						const potential = Object.keys(deployments).filter(version => version.match(new RegExp(stripped))).filter(version => deployments[version].date > failure.created);
						if(potential.length > 0){
							resolve = potential[0].date;
						}
						else{
							resolved = failure.resolved;
						}
					}
				}

				return {
					...failure,
					resolved,
					delta: resolved - failure.created
				}
			});
		}
		else if(repo.failures?.type === 1){
			const gh_pr = await exec(`./gh_pr.sh "${repo.id}"`);
			if(gh_pr.stderr){
				return Promise.reject(new Error(gh_pr.stderr));
			}
			const issues = {}
			gh_pr.stdout.split("\n").filter(l => l.length > 1).forEach((line, i) => {
				line = line.split(",");
				const issue = line[0];
				const pr = line[1];
				const sha = line[2];
				const issue_time = parseInt(line[3]);
				const merge_time = parseInt(line[4]);
				if(!issues[issue] || issues[issue].merge_time < merge_time){
					issues[issue] = {
						issue,
						pr,
						sha,
						issue_time,
						merge_time
					}
				}
			});
			failures = Object.keys(issues).map((issue, i) => {
				for (const version in deployments){
					if(deployments[version].commits.indexOf(issues[issue].sha) > -1 && deployments[version].date > issues[issue].issue_time){
						return {
							id: issue,
							critical: true,
							version: version,
							resolved: deployments[version].date,
							created: issues[issue].issue_time,
							delta: deployments[version].date - issues[issue].issue_time
						}
					}
				}
				return null;
			}).filter(i => i !== null);
		}

		failures.forEach((failure, i) => {
			const sorted = Object.keys(deployments).filter(k => deployments[k].date < failure.created).sort((a,b) => deployments[b].date - deployments[a].date);
			if(sorted.length > 0){
				deployments[sorted[0]].hasFailure = true;
				deployments[sorted[0]].hasCriticalFailure = deployments[sorted[0]].hasCriticalFailure || failure.critical;
			}
		});


		completed += 1
		console.log(`Completed ${repo.id} in ${Math.round((Date.now() - startTime) / 1000)}s (${completed}/${config.repos.length})`);
		return Promise.resolve({
			repo: repo.id,
			numDeployments,
			deploymentFrequency,
			totalCommits,
			totalDelta,
			averageDelta: totalDelta / totalCommits,
			deployments,
			failures,
			totalFailures: Object.keys(deployments).filter(k => deployments[k].hasFailure).length,
			totalCriticalFailures: Object.keys(deployments).filter(k => deployments[k].hasCriticalFailure).length,
			averageFailureDelta: failures.reduce((acc, nxt) => acc + nxt.delta, 0) / (failures.length || 1),
			averageCritialFailureDelta: failures.filter(f => f.critical).reduce((acc, nxt) => acc + nxt.delta, 0) / (failures.filter(f => f.critical).length || 1),
		});
	}
})).then(async results => {
	const output = {name: config.name, start: config.start, end: config.end, results}
	const serialized = JSON.stringify(output, null, 4);
	fs.writeFileSync(config.results, serialized);
	fs.createWriteStream(null, {fd: 3}).write(`${config.results}`);

	console.log("==========REPORT==========");
	await Promise.all(results.map(async (result, i) => {

		const freq = (await exec(`./print_time.sh ${Math.round(result.deploymentFrequency)}`)).stdout.trim();
		const leadTime = (await exec(`./print_time.sh ${Math.round(result.averageDelta)}`)).stdout.trim();
		const meanTime = (await exec(`./print_time.sh ${Math.round(result.averageFailureDelta)}`)).stdout.trim();
		const meanTimeCritical = (await exec(`./print_time.sh ${Math.round(result.averageCritialFailureDelta)}`)).stdout.trim();

		console.log(`----|${result.repo}|----`);
		console.log(`Deployment Frequency: ${performer(result.deploymentFrequency, DeploymentFrequencyScale)} Performer (Average: ${freq})`);
		console.log(`Lead Time for Changes: ${performer(result.averageDelta, LeadTimeforChangesScale)} Performer (Average: ${leadTime})`);
		if(result.failures.length == 0){
			console.log("Mean Time to Recover: n/a");
			console.log(`Change Failure Rate: n/a`);
		}
		else{
			console.log(`Mean Time to Recover: ${performer(result.averageFailureDelta, MeanTimetoRecoverScale)} Performer (Average: ${meanTime})`);
			if(result.totalCriticalFailures !== result.totalFailures && result.totalCriticalFailures !== 0){
				console.log(`Mean Time to Recover (High Priority): ${performer(result.averageCritialFailureDelta, MeanTimetoRecoverScale)} Performer (Average: ${meanTimeCritical})`);
				if(result.numDeployments > 0){
					console.log(`Change Failure Rate (High Priority): ${performer(result.totalCriticalFailures/ result.numDeployments, MeanTimetoRecoverScale)} Performer (${Math.round(result.totalCriticalFailures / result.numDeployments * 100)}%)`);
				}
			}
			if(result.numDeployments > 0){
				console.log(`Change Failure Rate: ${performer(result.totalFailures / result.numDeployments, ChangeFailureRateScale)} Performer (${Math.round(result.totalFailures / result.numDeployments * 100)}%)`);
			}
			else{
				console.log(`Change Failure Rate: n/a`);
			}
		}
	}));
	console.log("==========================");

});
