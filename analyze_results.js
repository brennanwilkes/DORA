const fs = require("fs")

const MINUTE = 60 * 1000;
const HOUR = MINUTE * 60;
const DAY = HOUR * 24;
const YEAR = DAY * 365;
const WEEK = YEAR / 52;
const MONTH =  YEAR / 12;
const MONTH4 = YEAR / 3;
const MONTH6 = YEAR / 2;

let data = JSON.parse(fs.readFileSync(process.argv[process.argv.length - 1]));

console.log(data)










// // const time = "created"
// const time = "resolved";
//
// const analysis = (data.results ?? [data.result]).map((result, i) => {
// 	const changeFailureRate = 100 * Object.keys(result.deployments).map(k => result.deployments[k]).filter(d => d.failures > 0 || d.hasFailure).length / (Object.keys(result.deployments).length || 1);
//
// 	const sorted = Object.keys(result.deployments).map(k => result.deployments[k]).sort((a,b) => a.date - b.date);
// 	const start = sorted[0].date;
// 	const end = sorted[sorted.length - 1].date;
// 	const deploymentFrequency = Object.keys(result.deployments).length / (end - start) * YEAR / 1000
//
//
// 	let sum = 0;
// 	let n = 0;
// 	Object.keys(result.deployments).map(k => result.deployments[k]).forEach((deployment, i) => {
// 		sum += deployment.totalDelta;
// 		n += deployment.commits.length;
// 	});
// 	const leadTimeForChanges = (n === 0) ? 0 : (sum / n / 60 / 60 / 24);
//
//
// 	sum = 0;
// 	n = 0;
// 	result.failures.forEach((fail, i) => {
// 		sum += (fail.resolved - fail.created);
// 		n += 1;
// 	});
// 	const meanTimeToRecover = (n === 0) ? 0 : (sum / n / 60 / 60 / 24);
//
// 	return {
// 		repo: result.repo,
// 		changeFailureRate,
// 		deploymentFrequency,
// 		leadTimeForChanges,
// 		meanTimeToRecover,
// 	}
// });
