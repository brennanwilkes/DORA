const fs = require("fs")
const exec = require("util").promisify(require("child_process").exec);

const fn = process.argv[2];
const SZZ_CACHE = "./SZZ_CACHE"

const main = async () => {
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

	if(fs.existsSync(SZZ_CACHE)){
		await fs.promises.unlink(SZZ_CACHE);
	}

	console.log(`Starting study ${config.name} from ${config.start} to ${config.end}`);

	let results = [];
	for (const repo of config.repos) {
		const result = await new Promise(async (resolve, reject) => {
			const failType = repo.failures?.type;
			console.log(`Analyzing ${repo.id} with deployment=${repo.deployment === 0 ? "releases" : "tags"}, failures=${failType === 0 ? "jira" : (failType === 1 ? "issues" : "n/a")}`);
			const startTime = Date.now();

			const analysis = await exec(`./analyze.sh ${repo.id} ${repo.deployment} "${config.end}" "${config.start}"`, {maxBuffer: 1024 * 1024 * 1024});
			if(analysis.stderr){
				console.error("*******************")
				console.error(analysis.stderr)
				console.error("*******************")
			}
			else{
				const data = analysis.stdout.split("\n");
				const numDeployments = parseInt(data[0].split(",")[3])
				const deploymentFrequency = parseInt(data[0].split(",")[4])
				const deployments = {}
				let totalCommits = 0;
				let totalDelta = 0;
				let duplicates = 0;

				data.slice(1).filter(l => l.length > 1).forEach((line, i) => {
					line = line.split(",")
					const tag = line[1]
					const sha = line[2]
					const date = parseInt(line[3]);
					const delta = parseInt(line[5])
					const diff = line[6]
					if(!deployments[tag]){
						deployments[tag] = {
							commits:[],
							diffs: [],
							deltas: [],
							totalDelta: 0,
							averageDelta: 0}
					}

					if(Object.keys(deployments).some(tag => (deployments[tag].commits.indexOf(sha) !== -1) || (deployments[tag].diffs.indexOf(diff) !== -1))){
						// console.log(`Found duplicate SHA (${sha}/${diff}/${tag}) exists already`)
						duplicates += 1;
					}
					else{
						deployments[tag].commits = [...deployments[tag].commits, sha]
						deployments[tag].diffs = [...deployments[tag].diffs, diff]
						deployments[tag].deltas = [...deployments[tag].deltas, delta]
						deployments[tag].totalDelta += delta;
						deployments[tag].date = date;
						deployments[tag].averageDelta = deployments[tag].totalDelta / deployments[tag].commits.length
						deployments[tag].failures = 0;
						deployments[tag].criticalFailures = 0;
						totalCommits += 1;
						totalDelta += delta;
					}
				});

				let failures = []
				if(repo.failures?.type === 0){
					const jira = await exec(`./jira.sh "${repo.failures.url}" "${repo.failures.project}"`);
					if(jira.stderr){
						console.error("*******************")
						console.error(jira.stderr)
						console.error("*******************")
					}
					const jiraData = JSON.parse(jira.stdout);
					failures = jiraData.issues.map((issue, i) => ({
						id: issue.key,
						critical: issue.fields.priority.name === "High" || issue.fields.priority.name === "Highest",
						fixed_by: issue.fields.fixVersions?.[0]?.name,
						resolved: new Date(issue.fields.fixVersions?.[0]?.releaseDate ?? issue.fields.resolutiondate).getTime() / 1000,
						created: new Date(issue.fields.created).getTime() / 1000
					})).map(failure => {
						let resolved;
						if(!failure.fixed_by){
							resolved = failure.resolved;
							const sorted = Object.keys(deployments).filter(k => deployments[k].date > failure.created).sort((a,b) => deployments[a].date - deployments[b].date);
							if(sorted.length > 0){
								failure.fixed_by = sorted[0];
							}
						}
						else{
							const tag = failure.fixed_by
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
									resolved = deployments[potential[0]].date;
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
					const custom = (repo.failures?.custom ?? []).join(" ");
					const gh_pr = await exec(
						`./gh_pr.sh "${repo.id}" "${new Date(config.start).getTime() / 1000}" "${new Date(config.end).getTime() / 1000}"${custom.length > 0 ? ` "${custom}"` : ""}`,
						{maxBuffer: 1024 * 1024 * 1024});
					if(gh_pr.stderr){
						console.error("*******************")
						console.error(gh_pr.stderr)
						console.error("*******************")
					}
					let issues = []
					gh_pr.stdout.split("\n").filter(l => l.length > 1).forEach((line, i) => {
						line = line.split(",");
						const issue = line[0];
						const pr = line[1];
						const sha = line[2];
						const issue_time = parseInt(line[3]);
						const merge_time = parseInt(line[4]);
						const diff = line[5];
						const isMerge = line[6] === "merge";
						issues = [...issues, {
							issue,
							pr,
							sha,
							issue_time,
							merge_time,
							diff,
							isMerge
						}];
					});
					failures = issues.map((issue, i) => {
						for (const version in deployments){
							if(
								(deployments[version].commits.indexOf(issue.sha) > -1 || deployments[version].diffs.indexOf(issue.diff) > -1)
								&& deployments[version].date > issue.issue_time){
								return {
									id: issue.issue,
									critical: true,
									fixed_by: version,
									resolved: deployments[version].date,
									created: issue.issue_time,
									delta: deployments[version].date - issue.issue_time,
									sha: issue.sha,
									diff: issue.diff,
									merge_commit: issue.isMerge ? issue.sha : undefined,
									merge_diff: issue.isMerge ? issue.diff : undefined
								}
							}
						}
						return null;
					}).filter(i => i !== null);

					const uniqueFailures = {}
					failures.forEach((failure, i) => {
						if(!uniqueFailures[failure.id] || uniqueFailures[failure.id].delta < failure.delta){
							uniqueFailures[failure.id] = failure;
						}
						else{
							uniqueFailures[failure.id].merge_commit = uniqueFailures[failure.id].merge_commit ?? failure.merge_commit
							uniqueFailures[failure.id].merge_diff = uniqueFailures[failure.id].merge_diff ?? failure.merge_diff
						}
					});

					failures = Object.keys(uniqueFailures).map(k => uniqueFailures[k]);

					const mapping = Object.keys(deployments).map(v => deployments[v]).map(d => {
						let map = [];
						for(let i=0; i<d.commits.length; i++){
							map = [...map, {sha: d.commits[i], hash: d.diffs[i]}];
						}
						return map;
					}).flat();

					for (const i in failures){
						const failure = failures[i];
						const mappedSha = mapping.filter(m => m.hash === failure.diff)?.[0]?.sha;
						const mappedMergeSha = mapping.filter(m => m.hash === failure.merge_diff)?.[0]?.sha;
						await exec(`./log.sh . "${i}/${failures.length}"`);
						const find_issues = await exec(`./find_fix_lines.sh ${(mappedMergeSha ?? failure.merge_commit) ?? (mappedSha ?? failure.sha)},${failure.id},${failure.created} ${repo.id}`);
						if(find_issues.stderr){
							console.error("*******************")
							console.error(find_issues.stderr)
							console.error("*******************")
						}
						find_issues.stdout.split("\n").filter(l => l.length > 1).forEach((line, i) => {
							const fix_commit = line.split(",")[0];
							const fix_inducing_commit = line.split(",")[1];
							const fix_inducing_diff = line.split(",")[2];
							const issue = line.split(",")[3];
							const file = line.split(",")[4];

							failure.inducing_commits = [...(failure.inducing_commits ?? []), fix_inducing_commit];
							failure.inducing_commits_diff = [...(failure.inducing_commits_diff ?? []), fix_inducing_diff];

							Object.keys(deployments).forEach((version, i) => {
								if(deployments[version].commits.indexOf(fix_inducing_commit) > -1 || deployments[version].diffs.indexOf(fix_inducing_diff) > -1){
									deployments[version].failures += 1;
									failure.induced_by = [...(failure.induced_by ?? []), version];
								}
							});
						});
					}
				}

				if(repo.failures?.type === 0){
					failures.forEach((failure, i) => {
						const sorted = Object.keys(deployments).filter(k => deployments[k].date < failure.created).sort((a,b) => deployments[b].date - deployments[a].date);
						if(sorted.length > 0){
							deployments[sorted[0]].failures += 1;
							if(failure.critical){
								if(!deployments[sorted[0]].criticalFailures){
									deployments[sorted[0]].criticalFailures = 0;
								}
								deployments[sorted[0]].criticalFailures += 1;
							}
						}
					});
				}

				completed += 1
				console.log(`Completed ${repo.id} in ${Math.round((Date.now() - startTime) / 1000)}s (${completed}/${config.repos.length})`);
				resolve({
					repo: repo.id,
					numDeployments,
					deploymentFrequency,
					totalCommits,
					totalDelta,
					averageDelta: totalDelta / totalCommits,
					deployments,
					failures,
					totalFailures: Object.keys(deployments).filter(k => deployments[k].failures > 0).length,
					totalCriticalFailures: Object.keys(deployments).filter(k => deployments[k].criticalFailures > 0).length,
					averageFailureDelta: failures.reduce((acc, nxt) => acc + nxt.delta, 0) / (failures.length || 1),
					averageCriticalFailureDelta: failures.filter(f => f.critical).reduce((acc, nxt) => acc + nxt.delta, 0) / (failures.filter(f => f.critical).length || 1),
				});
			}
		}).catch(err => {
			console.error("ERR")
			console.error(err);
			console.error("ERR")
		});

		const freq = (await exec(`./print_time.sh ${Math.round(result.deploymentFrequency)}`)).stdout.trim();
		const leadTime = (await exec(`./print_time.sh ${Math.round(result.averageDelta)}`)).stdout.trim();
		const meanTime = (await exec(`./print_time.sh ${Math.round(result.averageFailureDelta)}`)).stdout.trim();
		const meanTimeCritical = (await exec(`./print_time.sh ${Math.round(result.averageCriticalFailureDelta)}`)).stdout.trim();

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
		const output = {name: `${config.name} - ${result.repo}`, start: config.start, end: config.end, result}
		const serialized = JSON.stringify(output, null, 4);
		fs.writeFileSync(`${result.repo.replace(/\//, "-")}-${config.results}`, serialized);

		results = [...results, result];
		await exec(`./cleanup.sh ${result.repo}`);
	}

	const output = {name: config.name, start: config.start, end: config.end, results}
	const serialized = JSON.stringify(output, null, 4);
	fs.writeFileSync(config.results, serialized);

}

main();
